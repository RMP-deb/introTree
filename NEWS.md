# introTree 0.1.0

* First tagged release.
* `DStatFilter` class: `loadTree()`, `loadTable()`, `filter()`,
  `sisterAdmixture()`, `saveResult()`.
* `sisterAdmixture()` gains `level = "clade"` (all tree-congruent pairs, not only
  cherries) and `summary = TRUE` (one row per clade and H3, showing whether
  significant pairs point at the same side).
* Small synthetic example data in `inst/extdata`.
* Tests moved to testthat; R CMD check runs on GitHub Actions.
* Licence changed from Apache-2.0 to GPL (>= 3). Earlier versions remain
  Apache-2.0.