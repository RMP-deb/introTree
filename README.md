# introTree

Tools such as 'ANGSD' report D-statistics for every trio arrangement, but
only arrangements whose H1 and H2 pairing agrees with a rooted species tree
are interpretable in that tree context. introTree filters D-statistic
(ABBA-BABA allele-sharing) tables to retain those trios. P-values and
Benjamini-Hochberg adjusted p-values are reported for information only;
significance is based on the Z-score threshold.

## Install

```r
install.packages("remotes")
remotes::install_github("RMP-deb/introTree")

install.packages("introTree")
```

## Use

```r
library(introTree)

f <- DStatFilter$new()
tree_file <- system.file("extdata", "example_tree.treefile", package = "introTree")
table_file <- system.file("extdata", "example_dstats.txt", package = "introTree")
f$loadTree(tree_file, "outgroup")
f$loadTable(table_file)
f$filter()
f                                  # summary
f$saveResult("dstat_clean.csv")
```

## Limits

A D-statistic alone does not establish that gene flow occurred or determine
its direction.

## Licence

GPL-3.0 license See `LICENSE`.
