\name{DStatFilter}
\alias{DStatFilter}
\alias{DStatFilter-class}
\docType{class}
\title{Tree-aware filter for D-statistic tables}
\description{
A reference class that stores a rooted species tree and a table of
D-statistic results, keeps only the rows whose topology agrees with the tree
(H1 and H2 closer to each other than either is to H3).
}
\section{Creating an object}{
\code{f <- DStatFilter$new()}
}
\section{Fields}{
\describe{
  \item{\code{tree}}{the rooted tree (an \code{ape} \code{phylo} object).}
  \item{\code{outgroup}}{name of the outgroup tip.}
  \item{\code{depth}}{matrix: depth of the common ancestor of every pair of tips.}
  \item{\code{data}}{the D-statistic table as loaded.}
  \item{\code{result}}{the table after \code{filter()}.}
}
}
\section{Methods}{
\describe{
  \item{\code{loadTree(file, outgroup_name)}}{read a single-tree Newick file
    and root it on the outgroup. Returns the object invisibly.}
  \item{\code{loadTable(file)}}{read a table with columns \code{H1}, \code{H2},
    \code{H3} and \code{Z} (Dsuite names \code{P1}, \code{P2}, \code{P3},
    \code{Z-score} are renamed); species labels are read as character.
    Returns the object invisibly.}
  \item{\code{filter(z_threshold = 3)}}{keep tree-congruent rows, add
    \code{congruent}, \code{abs_Z}, \code{p}, \code{p_adj} (Benjamini-Hochberg)
    and \code{significant}, sorted by decreasing \code{abs_Z}. Significance is
    based on \code{abs_Z > z_threshold}; \code{p} and \code{p_adj} are
    informational only. Rows containing the outgroup are dropped. Returns the
    object invisibly.}
  \item{\code{saveResult(file)}}{write \code{result} to a CSV file and return
    the object invisibly.}
  \item{\code{show()}}{print a summary of the tree and loaded and filtered
    row counts; returns \code{NULL} invisibly.}
}
}
\details{
A positive Z is taken to mean H3 shares more derived alleles with H2 (the
usual (ABBA - BABA) / (ABBA + BABA) convention).
}
\value{An object of class \code{DStatFilter}.}
\examples{
tree_file <- tempfile(fileext = ".tre")
table_file <- tempfile(fileext = ".txt")
writeLines("(((A,B),C),D,O);", tree_file)
write.table(
  data.frame(H1 = c("A", "A", "A", "C"), H2 = c("B", "C", "B", "D"),
             H3 = c("C", "B", "D", "A"), Z = c(4.2, 3.5, -3.8, 2)),
  table_file, sep = "\t", quote = FALSE, row.names = FALSE)

f <- DStatFilter$new()
f$loadTree(tree_file, "O")
f$loadTable(table_file)
f$filter()
f$result
unlink(c(tree_file, table_file))
}
