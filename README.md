# introTree

Tree-aware filtering of D-statistic (ABBA-BABA) result tables. Keeps only the
trios whose topology agrees with a rooted species tree. It reports p-values
and Benjamini-Hochberg adjusted p-values for information only; significance
is based on the Z-score threshold.

## Install

```r
install.packages("remotes")
remotes::install_github("RMP-deb/introTree")

```

## Use

```r
library(introTree)

f <- DStatFilter$new()
f$loadTree("alignment_chr6.fa.treefile", "macrovipera_chr6")
f$loadTable("vipera_dstat_jackknife.txt")
f$filter()
f                                  # summary
f$saveResult("dstat_clean.csv")
```

## Limits

A D-statistic cannot test for gene flow between the two members of a sister
pair themselves, and it cannot give the direction of gene flow.

## Licence

GPL-3.0 license See `LICENSE`.
