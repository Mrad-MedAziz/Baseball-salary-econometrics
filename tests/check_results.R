# Run after Analysis.r. Check the course dataset and committed report results.
script_arg <- grep('^--file=', commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg)) {
  setwd(dirname(dirname(normalizePath(sub('^--file=', '', script_arg[1])))))
}
x <- read.csv2('data/Baseball.csv', dec = '.', stringsAsFactors = FALSE)
stopifnot(nrow(x) == 322, ncol(x) == 24)
x <- na.omit(x)
stopifnot(nrow(x) == 263)
x$Hits_per_year <- x$Hits_career / x$Longevity
m <- lm(log(Salary_1987) ~ Longevity + Hits_per_year + Hits_86, data = x)
s <- summary(m)
stopifnot(abs(s$r.squared - 0.6214) < 0.0001,
          abs(s$adj.r.squared - 0.6170) < 0.0001)
sw <- shapiro.test(residuals(m))
stopifnot(abs(sw$statistic - 0.98776) < 0.00001,
          abs(sw$p.value - 0.02479) < 0.00001)
saved <- read.csv('results/m4_coefficients.csv')
stopifnot(isTRUE(all.equal(saved$Estimate, unname(coef(m)), tolerance = 1e-12)),
          all(saved$p_value > 0))
comparison <- read.csv('results/table1_model_comparison.csv')
stopifnot(comparison$Residual_SE[comparison$Model == 'M4'] == round(s$sigma, 3))
expected <- c('fig1_salary_histogram.png', 'fig2_salary_boxplot.png',
              'fig3_raw_vs_log_salary.png', 'fig4_simple_regressions.png',
              'fig5_m4_coefficients.png', 'fig6_m4_predicted_vs_actual.png',
              'fig7_qq_plots_4models.png', 'fig8_residuals_vs_fitted_4models.png')
stopifnot(all(file.exists(file.path('figures', expected))))
cat('Dataset, report metrics, saved coefficients, and figures verified.\n')
