# ==============================================================================
# Econometric Analysis of Major League Baseball Salaries (1986–1987)
# Authors: Anh Minh Ho, Bruno Meler, Mohamed Aziz Mrad (Sorbonne Université, 2026)
# ==============================================================================

# 1. Package Installation and Data Loading
if (!requireNamespace("ISLR", quietly = TRUE)) {
  install.packages("ISLR", repos = "https://cloud.r-project.org")
}
library(ISLR)

# Load dataset and drop observations with missing salaries (59 rows dropped -> n = 263)
data(Hitters)
df <- na.omit(Hitters)

# 2. Variable Definitions & Transformations
df$Salary_1987   <- df$Salary
df$log_Salary    <- log(df$Salary_1987)
df$Hits_86       <- df$Hits
df$Longevity     <- df$Years
df$Hits_per_year <- df$CHits / df$Years

# 3. Descriptive Statistics & Tukey Outlier Threshold
cat("=====================================================\n")
cat("            UNIVARIATE SALARY METRICS               \n")
cat("=====================================================\n")
cat("Sample Size (n): ", nrow(df), "\n")
cat("Mean Salary:     ", round(mean(df$Salary_1987), 1), "k$\n")
cat("Median Salary:   ", round(median(df$Salary_1987), 1), "k$\n")

q1  <- quantile(df$Salary_1987, 0.25)
q3  <- quantile(df$Salary_1987, 0.75)
iqr <- q3 - q1
tukey_cutoff <- q3 + 1.5 * iqr

cat("Q1 (25%):        ", round(q1, 1), "k$\n")
cat("Q3 (75%):        ", round(q3, 1), "k$\n")
cat("Tukey Cutoff:    ", round(tukey_cutoff, 1), "k$\n")
cat("Outliers Count:  ", sum(df$Salary_1987 > tukey_cutoff), "\n\n")

# 4. Fit Linear Models (M1 to M4)
m1 <- lm(log_Salary ~ Longevity, data = df)
m2 <- lm(log_Salary ~ Hits_86, data = df)
m3 <- lm(log_Salary ~ Hits_per_year, data = df)
m4 <- lm(log_Salary ~ Longevity + Hits_per_year + Hits_86, data = df)

# 5. Model Summaries
cat("=====================================================\n")
cat("                  MODEL ESTIMATION                  \n")
cat("=====================================================\n")
cat("--- Model M1: Longevity ---\n")
print(summary(m1))

cat("\n--- Model M2: Hits_86 ---\n")
print(summary(m2))

cat("\n--- Model M3: Hits_per_year ---\n")
print(summary(m3))

cat("\n--- Model M4: Combined Multiple Specification ---\n")
print(summary(m4))

# 6. Residual Diagnostics for Model M4
cat("=====================================================\n")
cat("               RESIDUAL DIAGNOSTICS                 \n")
cat("=====================================================\n")
sw_test <- shapiro.test(residuals(m4))
cat("Shapiro-Wilk W: ", round(sw_test$statistic, 4), "\n")
cat("p-value:        ", round(sw_test$p.value, 4), "\n\n")

# 7. Generate Diagnostic Figures
if (!dir.exists("figures")) {
  dir.create("figures")
}

# Residuals vs Fitted (Checks linearity and homoscedasticity)
png("figures/residuals_vs_fitted_m4.png", width = 800, height = 600, res = 120)
plot(
  fitted(m4), residuals(m4),
  xlab = "Fitted Values: log(Salary)",
  ylab = "Residuals",
  main = "Model M4: Residuals vs. Fitted Values",
  pch = 19, col = rgb(0.2, 0.4, 0.8, 0.6)
)
abline(h = 0, lty = 2, col = "red", lwd = 2)
lines(lowess(fitted(m4), residuals(m4)), col = "black", lwd = 2)
dev.off()

# Normal Q-Q Plot (Checks normality of residuals)
png("figures/qq_plot_m4.png", width = 800, height = 600, res = 120)
qqnorm(
  residuals(m4),
  main = "Model M4: Normal Q-Q Plot",
  pch = 19, col = rgb(0.8, 0.4, 0.1, 0.6)
)
qqline(residuals(m4), col = "red", lwd = 2)
dev.off()

cat("Diagnostic figures saved to ./figures/ directory.\n")