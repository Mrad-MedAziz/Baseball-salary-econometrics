# Data provenance

`Baseball.csv` is the course dataset supplied for the supervised research workshop at Sorbonne Université. It contains 322 rows and 24 source columns. Salaries are in thousands of US dollars for 1987; season statistics refer to 1986. There are 263 complete observations after removing missing entries.

The project follows Hoaglin and Velleman (1995), [A Critical Look at Some Analyses of Major League Baseball Salaries](https://doi.org/10.1080/00031305.1995.10476165).

This course CSV is not identical to `ISLR::Hitters` or to every corrected public copy of the historical dataset. Use the committed CSV to reproduce this project's results. Its public upstream version has not been established; the file is identified here by its course provenance and checksum rather than claiming an exact upstream match.

- Format: UTF-8, semicolon separator, decimal point, `NA` for missing values.
- SHA-256: `2e95163c6642b099abc257f06fa45ea40c642369502f8fdaa28a268e391e13e2`
- Derived variables in the script: `log_Salary = log(Salary_1987)` and `Hits_per_year = Hits_career / Longevity`.

The report's description of 28 variables should not be read as the number of source columns: the supplied CSV has 24. The reports are preserved as originally supplied.
