# Econometric Analysis of Major League Baseball Salaries (1986–1987)

**Authors:** Anh Minh Ho, Bruno Meler, Mohamed Aziz Mrad

**Course:** Sorbonne Université, supervised research workshop — grade 95/100

**Reports:** [Original French report, 11 pages](report.pdf) · [English version, 10 pages](English_Version_of_Report.pdf)

A three-person course project examining the association between baseball performance, career duration, and salary. We adapted general R code supplied by our instructor to the project and presented the work as it progressed. Tasks rotated within the team; Mohamed Aziz contributed particularly to mathematical interpretation and suggestions for addressing modelling problems.

## Reproduce the analysis

Requires R and its standard packages; no additional package installation is needed.

```bash
git clone https://github.com/Mrad-MedAziz/Baseball-salary-econometrics.git
cd Baseball-salary-econometrics
Rscript Analysis.r
Rscript tests/check_results.R
```

The script uses the committed [`data/Baseball.csv`](data/Baseball.csv), the course file used for the graded report. It writes figures to `figures/` and tables and console output to `results/`. See [data provenance and checksum](data/README.md).

**Data-version correction:** an earlier version of the reproduction script loaded `ISLR::Hitters`. That dataset does not reproduce this report. The script now uses the supplied course CSV explicitly. The original reports remain unchanged; current CSV outputs are authoritative for reproduced numerical values.

## Data and method

The source file contains 322 players and 24 columns, with 1986 performance statistics and 1987 salaries in thousands of US dollars. Removing rows with missing values leaves 263 hitters. The modelling approach follows [Hoaglin and Velleman (1995)](https://doi.org/10.1080/00031305.1995.10476165).

We fit three simple regressions and a combined ordinary least squares model for `log(Salary_1987)`. Career hits per year is computed as `Hits_career / Longevity`; this converts a career total into an annual average, without claiming independence from career duration.

| Model | Predictors | R² | Adjusted R² | Residual standard error |
| --- | --- | ---: | ---: | ---: |
| M1 | Career duration | 0.322 | 0.319 | 0.729 |
| M2 | Hits in 1986 | 0.263 | 0.260 | 0.760 |
| M3 | Career hits per year | 0.430 | 0.428 | 0.669 |
| M4 | All three predictors | 0.621 | 0.617 | 0.547 |

The combined model is approximately:

```text
log(Salary_1987) = 3.993 + 0.08752 * Longevity
                        + 0.006467 * Hits_per_year
                        + 0.006567 * Hits_86
```

It explains 62.1% of the **in-sample variance in log-salary**, not raw salary or held-out prediction performance. All three slope coefficients have p < 0.001 under the fitted model. Coefficients describe conditional associations, not causal effects. Their magnitudes cannot be compared directly as measures of importance because the predictors have different units.

## Diagnostics and limitations

Residual plots suggest nonlinearity in the simple career-duration model. Combining predictors reduces some visible structure but does not establish that all model assumptions hold. A logarithmic response compresses salary differences; it does not automatically guarantee constant error variance or normal residuals.

For M4, the Shapiro–Wilk test gives W = 0.9878 and p = 0.02479. This rejects exact normality at the 5% level. The statistic alone does not establish that departures are practically negligible. Normality is distinct from the Gauss–Markov assumptions.

The analysis is observational, excludes players with missing salaries, and does not evaluate held-out predictive accuracy. Possible omitted factors include contract status, defensive position, and team context; this study does not identify how much unexplained variance each factor accounts for. A nonlinear career-duration term remains a possible extension.

The archived reports contain broader interpretations than these checks support. In particular, their statements about guaranteed variance stabilization, negligible nonnormality, elasticity, and predictor dominance should be read with the qualifications above. The source CSV has 24 columns, rather than 28 raw variables.

## Figures and outputs

| Figure | Output |
| --- | --- |
| Salary distribution | [Histogram](figures/fig1_salary_histogram.png) |
| Salary outliers | [Boxplot](figures/fig2_salary_boxplot.png) |
| Raw and log-salary | [Histograms](figures/fig3_raw_vs_log_salary.png) |
| Simple regressions | [M1–M3](figures/fig4_simple_regressions.png) |
| Combined-model coefficients | [95% confidence intervals](figures/fig5_m4_coefficients.png) |
| In-sample fitted values | [Predicted versus actual](figures/fig6_m4_predicted_vs_actual.png) |
| Residual normality | [Q–Q plots](figures/fig7_qq_plots_4models.png) |
| Residual structure | [Residuals versus fitted](figures/fig8_residuals_vs_fitted_4models.png) |

Full results: [model comparison](results/table1_model_comparison.csv), [coefficients](results/m4_coefficients.csv), and [analysis log](results/analysis_output.txt).
