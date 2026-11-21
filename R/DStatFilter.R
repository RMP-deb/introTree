# introTree: tree-aware filtering of D-statistic tables
# Copyright (C) 2026 Ruben Muller-Perol
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
pairKey <- function(a, b) {
  ifelse(a < b, paste(a, b), paste(b, a))
}



DStatFilter <- setRefClass("DStatFilter",

  # Fields = the data each object stores
  fields = list(
    tree     = "ANY",         # rooted tree (ape phylo object)
    outgroup = "character",   # name of the outgroup tip
    depth    = "matrix",      # depth of the common ancestor for every pair of tips
    data     = "data.frame",  # the D-statistic table as loaded
    result   = "data.frame"   # the table after filtering
  ),

  # Methods = the things an object can do
  methods = list(

    # Read the tree, root it, and work out the depth lookup table
    loadTree = function(file, outgroup_name) {
      tr <- read.tree(file)
      if (inherits(tr, "multiPhylo")) {
        stop("Tree file must contain exactly one tree")
      }

      # check the outgroup name is really in the tree
      if (!(outgroup_name %in% tr$tip.label)) {
        stop("Outgroup '", outgroup_name, "' is not a tip in the tree")
      }

      # root on the outgroup
      tr <- root(tr, outgroup = outgroup_name, resolve.root = TRUE)

      # give every branch length 1, so depth = number of steps from the root
      # (bigger depth = more recent)
      tr <- compute.brlen(tr, 1)

      # matrix of common ancestors for every pair of tips, worked out once
      m <- mrca(tr)
      node_depth <- node.depth.edgelength(tr)

      # save into the object's fields (<<- changes the field, not a local copy)
      tree     <<- tr
      outgroup <<- outgroup_name
      depth    <<- matrix(node_depth[m], nrow(m), dimnames = dimnames(m))

      invisible(.self)   # returning the object lets you chain methods
    },

    # Read the D-statistic table
    loadTable = function(file) {
      d <- read.table(file, header = TRUE, stringsAsFactors = FALSE,
                      check.names = FALSE)

      # rename Dsuite style column names to H1 H2 H3 Z
      names(d)[names(d) == "P1"]      <- "H1"
      names(d)[names(d) == "P2"]      <- "H2"
      names(d)[names(d) == "P3"]      <- "H3"
      names(d)[names(d) == "Z-score"] <- "Z"

      # check the columns we need are there
      if (!all(c("H1", "H2", "H3", "Z") %in% names(d))) {
        stop("Table needs columns H1, H2, H3 and Z")
      }
      d[c("H1", "H2", "H3")] <- lapply(d[c("H1", "H2", "H3")], as.character)

      data <<- d
      invisible(.self)
    },

    # Keep only rows where H1 and H2 are closer to each other than to H3
    filter = function(z_threshold = 3) {
      if (nrow(depth) == 0) stop("Run loadTree() first")
      d <- data

      # drop any rows that contain the outgroup
      has_outgroup <- d$H1 == outgroup | d$H2 == outgroup | d$H3 == outgroup
      d <- d[!has_outgroup, ]

      # check every species name in the table is a tip in the tree
      table_names <- unique(c(d$H1, d$H2, d$H3))
      if (!all(table_names %in% rownames(depth))) {
        bad <- table_names[!(table_names %in% rownames(depth))]
        stop("Names not in tree: ", paste(head(bad, 5), collapse = ", "))
      }

      # depth of the common ancestor for each pair in every row
      d12 <- depth[cbind(d$H1, d$H2)]
      d13 <- depth[cbind(d$H1, d$H3)]
      d23 <- depth[cbind(d$H2, d$H3)]

      # congruent = H1 and H2 share a more recent ancestor than either does with H3
      # (H1 != H2 stops a species being compared with itself)
      d$congruent <- d12 > d13 & d12 > d23 & d$H1 != d$H2
      d <- d[d$congruent, ]
      d <- d[!is.na(d$Z), ]

      # significance: p value from Z, then correct for many tests (BH)
      d$abs_Z       <- abs(d$Z)
      d$p           <- 2 * pnorm(-d$abs_Z)
      d$p_adj       <- p.adjust(d$p, method = "BH")
      d$significant <- d$abs_Z > z_threshold

      # strongest signals first
      d <- d[order(-d$abs_Z), ]
      rownames(d) <- NULL

      result <<- d
      invisible(.self)
    },

    # Write the filtered table to a file
    saveResult = function(file) {
      write.csv(result, file, row.names = FALSE)
      message("Saved ", nrow(result), " rows to ", file)
      invisible(.self)
    },

    # What you see when you type the object's name
    show = function() {
      cat("DStatFilter object\n")
      cat("  tips in tree:   ", nrow(depth), "\n")
      cat("  rows loaded:    ", nrow(data), "\n")
      cat("  rows after filter:", nrow(result), "\n")
    }
  )
)
