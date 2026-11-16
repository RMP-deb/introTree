This is a new submission.

## Test environments

- Local x86_64-pc-linux-gnu, R 4.6.2

## R CMD check results

- `devtools::check(args = "--as-cran")`: 0 errors, 0 warnings, 0 notes.
- `urlchecker::url_check()`: all URLs are correct.
- `devtools::spell_check()` flagged only package-specific or technical terms:
  ABBA, ANGSD, Benjamini, doi, Durand, et, molbev, and msr.

The `<<-` assignments update fields of the `DStatFilter` Reference Class
object; they do not assign variables in the global environment.

The package licence changed from Apache-2.0 to GPL (>= 3) before this first
CRAN release. Earlier versions remain under Apache-2.0.
