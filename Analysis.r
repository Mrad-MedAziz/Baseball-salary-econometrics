# ==============================================================================
# Econometric Analysis of Major League Baseball Salaries (1986-1987)
# Authors: Anh Minh Ho, Bruno Meler, Mohamed Aziz Mrad (Sorbonne Universite, 2026)
#
# Reproduces every figure, table, and console log of the report:
#   Figure 1  Salary histogram                     figures/fig1_salary_histogram.png
#   Figure 2  Salary boxplot (Tukey outliers)      figures/fig2_salary_boxplot.png
#   Figure 3  Raw vs log(Salary) histograms        figures/fig3_raw_vs_log_salary.png
#   Figure 4  Simple regressions M1, M2, M3        figures/fig4_simple_regressions.png
#   Figure 5  M4 coefficients with 95% CI          figures/fig5_m4_coefficients.png
#   Figure 6  M4 predicted vs actual               figures/fig6_m4_predicted_vs_actual.png
#   Figure 7  Normal Q-Q plots, M1 to M4           figures/fig7_qq_plots_4models.png
#   Figure 8  Residuals vs fitted, M1 to M4        figures/fig8_residuals_vs_fitted_4models.png
#   Standalone M4 diagnostics                      figures/qq_plot_m4.png
#                                                  figures/residuals_vs_fitted_m4.png
#   Table 1   Model comparison                     results/table1_model_comparison.csv
#   M4 coefficients with CI and p-values           results/m4_coefficients.csv
#   Full console output                            results/analysis_output.txt
# ==============================================================================

dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
sink("results/analysis_output.txt", split = TRUE)

# ------------------------------------------------------------------------------
# 1. Data loading and cleaning
# ------------------------------------------------------------------------------
load_hitters <- function() {
  if (requireNamespace("ISLR", quietly = TRUE)) {
    return(ISLR::Hitters)
  }
  if (file.exists("Hitters.csv")) {
    return(read.csv("Hitters.csv"))
  }
  install.packages("ISLR", repos = "https://cloud.r-project.org")
  return(ISLR::Hitters)
}

raw <- load_hitters()
cat("Raw dataset:", nrow(raw), "rows,", ncol(raw), "variables\n")
n_qual <- sum(sapply(raw, function(x) is.factor(x) || is.character(x)))
cat("Qualitative variables:", n_qual, "\n")

df <- na.omit(raw)
cat("Rows dropped (missing Salary):", nrow(raw) - nrow(df),
    "-> final sample n =", nrow(df), "\n\n")

df$Salary_1987   <- df$Salary                 # thousands of dollars
df$log_Salary    <- log(df$Salary_1987)
df$Hits_86       <- df$Hits
df$Longevity     <- df$Years
df$Hits_per_year <- df$CHits / df$Years       # career hits per year of career

sal <- df$Salary_1987

# ------------------------------------------------------------------------------
# 2. Descriptive statistics and Tukey outlier threshold
# ------------------------------------------------------------------------------
q1       <- unname(quantile(sal, 0.25))
q3       <- unname(quantile(sal, 0.75))
iqr      <- q3 - q1
tukey_up <- q3 + 1.5 * iqr
n_out    <- sum(sal > tukey_up)

cat("=====================================================\n")
cat("            UNIVARIATE SALARY METRICS\n")
cat("=====================================================\n")
cat(sprintf("Sample size (n):        %d\n", length(sal)))
cat(sprintf("Mean salary:            %.1f k$\n", mean(sal)))
cat(sprintf("Median salary:          %.1f k$\n", median(sal)))
cat(sprintf("Q1 (25%%):               %.1f k$\n", q1))
cat(sprintf("Q3 (75%%):               %.1f k$\n", q3))
cat(sprintf("IQR:                    %.1f k$\n", iqr))
cat(sprintf("Tukey upper threshold:  %.1f k$\n", tukey_up))
cat(sprintf("Outliers:               %d (%.1f%% of sample)\n",
            n_out, 100 * n_out / length(sal)))
cat(sprintf("Mean log(Salary):       %.2f\n", mean(df$log_Salary)))
cat(sprintf("Median log(Salary):     %.2f\n\n", median(df$log_Salary)))

# ------------------------------------------------------------------------------
# 3. Regression models M1 to M4
# ------------------------------------------------------------------------------
m1 <- lm(log_Salary ~ Longevity, data = df)
m2 <- lm(log_Salary ~ Hits_86, data = df)
m3 <- lm(log_Salary ~ Hits_per_year, data = df)
m4 <- lm(log_Salary ~ Longevity + Hits_per_year + Hits_86, data = df)
models <- list(M1 = m1, M2 = m2, M3 = m3, M4 = m4)

cat("=====================================================\n")
cat("                  MODEL ESTIMATION\n")
cat("=====================================================\n")
for (nm in names(models)) {
  cat("\n--- Model", nm, "---\n")
  print(summary(models[[nm]]))
}

# Table 1: model comparison
table1 <- data.frame(
  Model       = names(models),
  Predictors  = c("Longevity", "Hits_86", "Hits_per_year", "Combined"),
  R2          = round(sapply(models, function(m) summary(m)$r.squared), 3),
  Adj_R2      = round(sapply(models, function(m) summary(m)$adj.r.squared), 3),
  Residual_SE = round(sapply(models, function(m) summary(m)$sigma), 3),
  row.names   = NULL
)
cat("\n--- Table 1: Model comparison ---\n")
print(table1, row.names = FALSE)
write.csv(table1, "results/table1_model_comparison.csv", row.names = FALSE)

# M4 coefficients with confidence intervals and percentage effects
ci <- confint(m4, level = 0.95)
m4_coefs <- data.frame(
  Term       = names(coef(m4)),
  Estimate   = coef(m4),
  CI_low     = ci[, 1],
  CI_high    = ci[, 2],
  p_value    = summary(m4)$coefficients[, 4],
  Pct_change = 100 * (exp(coef(m4)) - 1),
  row.names  = NULL
)
m4_coefs$Pct_change[m4_coefs$Term == "(Intercept)"] <- NA
m4_coefs[, 2:6] <- round(m4_coefs[, 2:6], 5)
cat("\n--- Model M4 coefficients (95% CI) ---\n")
print(m4_coefs, row.names = FALSE)
write.csv(m4_coefs, "results/m4_coefficients.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 4. Residual diagnostics: Shapiro-Wilk test for each model
# ------------------------------------------------------------------------------
cat("\n=====================================================\n")
cat("               RESIDUAL DIAGNOSTICS\n")
cat("=====================================================\n")
for (nm in names(models)) {
  sw <- shapiro.test(residuals(models[[nm]]))
  cat(sprintf("%s  Shapiro-Wilk W = %.4f, p = %.4g\n",
              nm, sw$statistic, sw$p.value))
}

# ------------------------------------------------------------------------------
# 5. Figures (All 8 Report Figures + Standalone M4 Plots)
# ------------------------------------------------------------------------------
open_png <- function(file, w = 900, h = 600) {
  png(file, width = w, height = h, res = 120)
}

blue   <- rgb(0.25, 0.50, 0.75, 0.60)
orange <- rgb(0.90, 0.50, 0.15, 0.65)

# Figure 1: Histogram of raw salaries with mean and median ---------------------
open_png("figures/fig1_salary_histogram.png", 850, 550)
par(mar = c(4.5, 4.5, 3, 2))
hist(sal, breaks = 30, col = "#79a6d2", border = "#2b3e50",
     main = "Distribution of 1987 Salaries",
     xlab = "Salary_1987 (thousands of dollars)", ylab = "Frequency",
     xlim = c(0, 2500))
grid(col = "lightgray", lty = "dotted")
abline(v = mean(sal),   col = "#d62728", lty = 2, lwd = 2.5)
abline(v = median(sal), col = "#1b7837", lty = 2, lwd = 2.5)
legend("topright",
       legend = c(sprintf("Mean: %.1f", mean(sal)),
                  sprintf("Median: %.1f", median(sal))),
       col = c("#d62728", "#1b7837"), lty = 2, lwd = 2.5, bg = "white")
dev.off()

# Figure 2: Boxplot of 1987 salaries -------------------------------------------
open_png("figures/fig2_salary_boxplot.png", 650, 650)
par(mar = c(3, 4.5, 3, 2))
boxplot(sal, col = "#add8e6", border = "black", medcol = "red", medlwd = 2.5,
        pch = 1, cex = 1.1,
        main = "Box Plot : Salary_1987",
        ylab = "Salary_1987 (thousands of dollars)",
        ylim = c(0, 2500))
grid(nx = NA, ny = NULL, col = "lightgray", lty = "solid")
dev.off()

# Figure 3: Raw vs log(Salary) histograms side by side -------------------------
open_png("figures/fig3_raw_vs_log_salary.png", 1200, 520)
par(mfrow = c(1, 2), oma = c(0, 0, 2, 0), mar = c(4.5, 4.5, 2.5, 1.5))

hist(sal, breaks = 30, col = "#79a6d2", border = "#2b3e50",
     main = "Raw Salary (right-skewed)",
     xlab = "Salary_1987 (k$)", ylab = "Frequency", xlim = c(0, 2500))
grid(col = "lightgray", lty = "dotted")
abline(v = mean(sal),   col = "#d62728", lty = 2, lwd = 2)
abline(v = median(sal), col = "#1b7837", lty = 2, lwd = 2)
legend("topright",
       legend = c(sprintf("Mean: %.1f", mean(sal)),
                  sprintf("Median: %.1f", median(sal))),
       col = c("#d62728", "#1b7837"), lty = 2, lwd = 2, cex = 0.85, bg = "white")

hist(df$log_Salary, breaks = 28, col = "#f5a642", border = "#2b3e50",
     main = "log(Salary) (more symmetric)",
     xlab = "log(Salary_1987)", ylab = "Frequency")
grid(col = "lightgray", lty = "dotted")
abline(v = mean(df$log_Salary),   col = "#d62728", lty = 2, lwd = 2)
abline(v = median(df$log_Salary), col = "#1b7837", lty = 2, lwd = 2)
legend("topright",
       legend = c(sprintf("Mean: %.2f", mean(df$log_Salary)),
                  sprintf("Median: %.2f", median(df$log_Salary))),
       col = c("#d62728", "#1b7837"), lty = 2, lwd = 2, cex = 0.85, bg = "white")
mtext("Salary_1987 : Raw vs log(Salary)", outer = TRUE, cex = 1.2, font = 2)
par(mfrow = c(1, 1))
dev.off()

# Figure 4: Simple regressions M1 to M3 (with equations + R² + p-values) -------
open_png("figures/fig4_simple_regressions.png", 1450, 480)
par(mfrow = c(1, 3), oma = c(0, 0, 2.2, 0), mar = c(4.5, 4.5, 2.5, 1.5))
panels <- list(
  list(model = m1, x = df$Longevity, var_name = "Longevity",
       xlab = "Years of Experience (Longevity)",
       main = "Model 1 : log(Salary) ~ Longevity"),
  list(model = m2, x = df$Hits_86, var_name = "Hits_86",
       xlab = "Hits in 1986 (Hits_86)",
       main = "Model 2 : log(Salary) ~ Hits_86"),
  list(model = m3, x = df$Hits_per_year, var_name = "Hits_per_year",
       xlab = "Hits per Year (Hits_per_year)",
       main = "Model 3 : log(Salary) ~ Hits_per_year")
)
for (p in panels) {
  plot(p$x, df$log_Salary, pch = 19, col = blue,
       xlab = p$xlab, ylab = "log(Salary_1987)", main = p$main)
  grid(col = "lightgray", lty = "dotted")
  abline(p$model, col = "#c91d22", lwd = 2.5)
  legend("topleft",
         legend = c(
           sprintf("log(Salary) = %.3f + %.4f * %s",
                   coef(p$model)[1], coef(p$model)[2], p$var_name),
           sprintf("R² = %.3f  |  p < 0.001", summary(p$model)$r.squared)
         ),
         bty = "n", cex = 0.85)
  legend("bottomright",
         legend = c("Players", "Regression line"),
         pch = c(19, NA), lty = c(NA, 1), lwd = c(NA, 2.5),
         col = c(blue, "#c91d22"), cex = 0.8, bg = "white")
}
mtext("Simple Regressions — log(Salary) vs Predictor", outer = TRUE, cex = 1.2, font = 2)
par(mfrow = c(1, 1))
dev.off()

# Figure 5: M4 coefficients with 95% confidence intervals ----------------------
est  <- coef(m4)[-1]
ci_p <- ci[-1, , drop = FALSE]
pv   <- summary(m4)$coefficients[-1, 4]

open_png("figures/fig5_m4_coefficients.png", 850, 480)
par(mar = c(4.5, 8.5, 3.5, 2))
bp <- barplot(est, horiz = TRUE, names.arg = names(est), las = 1,
              col = ifelse(pv < 0.05, "#369b36", "grey70"),
              border = "#1e591e",
              xlim = c(0, max(ci_p[, 2]) * 1.12),
              xlab = "Coefficient (effect on log(Salary))",
              main = "Model 4 — Coefficients with 95% Confidence Intervals\n(green = significant p < 0.05)")
grid(nx = NULL, ny = NA, col = "lightgray", lty = "dotted")
arrows(ci_p[, 1], bp, ci_p[, 2], bp, angle = 90, code = 3,
       length = 0.06, lwd = 2, col = "black")
abline(v = 0, lty = 2, col = "red", lwd = 1.5)
dev.off()

# Figure 6: M4 predicted vs actual ---------------------------------------------
open_png("figures/fig6_m4_predicted_vs_actual.png", 750, 600)
par(mar = c(4.5, 4.5, 3.5, 2))
plot(fitted(m4), df$log_Salary, pch = 19, col = orange,
     xlab = "Predicted log(Salary)", ylab = "Actual log(Salary)",
     main = sprintf("Model 4 — Predicted vs Actual\nR² = %.3f", summary(m4)$r.squared))
grid(col = "lightgray", lty = "dotted")
abline(0, 1, col = "#c91d22", lty = 2, lwd = 2.5)
legend("topleft", legend = "Perfect fit (y = x)", col = "#c91d22",
       lty = 2, lwd = 2.5, bg = "white")
dev.off()

# Figure 7: Normal Q-Q plots for M1 to M4 (M1-M3 blue, M4 orange) --------------
qq_panel <- function(model, title, pt_col) {
  r <- residuals(model)
  qqnorm(r, main = title, xlab = "Theoretical Quantiles",
         ylab = "Residual Quantiles", pch = 19, col = pt_col)
  grid(col = "lightgray", lty = "dotted")
  qqline(r, col = "#c91d22", lwd = 2)
}

open_png("figures/fig7_qq_plots_4models.png", 1050, 880)
par(mfrow = c(2, 2), oma = c(0, 0, 2.5, 0), mar = c(4.2, 4.2, 2.5, 1.5))
qq_panel(m1, "M1: ~Longevity",     blue)
qq_panel(m2, "M2: ~Hits_86",       blue)
qq_panel(m3, "M3: ~Hits_per_year", blue)
qq_panel(m4, "M4: Multiple",       orange)
mtext("Q-Q Plots of Residuals — Normality", outer = TRUE, cex = 1.25, font = 2)
par(mfrow = c(1, 1))
dev.off()

# Standalone M4 Q-Q plot
open_png("figures/qq_plot_m4.png", 800, 600)
qq_panel(m4, "Model M4: Normal Q-Q Plot", orange)
dev.off()

# Figure 8: Residuals vs fitted values for M1 to M4 ----------------------------
rvf_panel <- function(model, title, pt_col) {
  f <- fitted(model)
  r <- residuals(model)
  plot(f, r, pch = 19, col = pt_col,
       xlab = "Fitted Values", ylab = "Residuals", main = title)
  grid(col = "lightgray", lty = "dotted")
  abline(h = 0, lty = 2, col = "#c91d22", lwd = 2)
  lines(lowess(f, r), col = "black", lwd = 2.2)
  legend("topright", legend = "Trend", col = "black", lwd = 2.2, cex = 0.8, bg = "white")
}

open_png("figures/fig8_residuals_vs_fitted_4models.png", 1050, 880)
par(mfrow = c(2, 2), oma = c(0, 0, 2.5, 0), mar = c(4.2, 4.2, 2.5, 1.5))
rvf_panel(m1, sprintf("M1: ~Longevity | R²=%.3f",     summary(m1)$r.squared), blue)
rvf_panel(m2, sprintf("M2: ~Hits_86 | R²=%.3f",       summary(m2)$r.squared), blue)
rvf_panel(m3, sprintf("M3: ~Hits_per_year | R²=%.3f", summary(m3)$r.squared), blue)
rvf_panel(m4, sprintf("M4: Multiple | R²=%.3f",       summary(m4)$r.squared), orange)
mtext("Residuals vs Fitted Values — 4 Models", outer = TRUE, cex = 1.25, font = 2)
par(mfrow = c(1, 1))
dev.off()

# Standalone M4 residuals vs fitted plot
open_png("figures/residuals_vs_fitted_m4.png", 800, 600)
rvf_panel(m4, "Model M4: Residuals vs. Fitted Values", blue)
dev.off()

# ------------------------------------------------------------------------------
# 6. Summary of outputs
# ------------------------------------------------------------------------------
cat("\n=====================================================\n")
cat("                  OUTPUT FILES\n")
cat("=====================================================\n")
print(list.files("figures", pattern = "\\.png$"))
print(list.files("results"))

sink()
