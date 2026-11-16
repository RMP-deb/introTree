# Core tests for introTree.


# Writes a tiny tree and table to temporary files and returns their paths.
# Tree: ((((A,B),C),D),O) once rooted on O. A+B is a cherry.
make_tiny <- function(rows = NULL, tree_text = "(((A,B),C),D,O);") {
  if (is.null(rows)) {
    rows <- data.frame(
      H1 = c("A", "A", "A", "A", "C"),
      H2 = c("B", "C", "B", "B", "D"),
      H3 = c("C", "B", "D", "O", "A"),
      Z  = c(4.2, 3.5, -3.8, 9, 2),
      stringsAsFactors = FALSE)
  }
  tree_file  <- tempfile(fileext = ".tre")
  table_file <- tempfile(fileext = ".txt")
  writeLines(tree_text, tree_file)
  write.table(rows, table_file, sep = "\t", quote = FALSE, row.names = FALSE)
  list(tree = tree_file, table = table_file)
}

test_that("only tree-congruent rows are kept and outgroup rows are dropped", {
  p <- make_tiny()
  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter()
  # (A,B;C) and (A,B;D) fit the tree. (A,C;B) and (C,D;A) do not. The O row is dropped.
  expect_equal(nrow(f$result), 2)
  expect_true(all(f$result$H1 == "A" & f$result$H2 == "B"))
  expect_true(all(f$result$congruent))
})

test_that("rows with missing Z values are excluded from filtered results", {
  rows <- data.frame(H1 = c("A", "A"), H2 = c("B", "B"), H3 = c("C", "C"),
                     Z = c(NA_real_, 5))
  p <- make_tiny(rows)
  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter()
  expect_equal(nrow(f$result), 1)
  expect_false(anyNA(f$result$Z))
  expect_equal(f$result$Z, 5)
})

test_that("numeric species names are treated as character labels", {
  rows <- data.frame(H1 = "10", H2 = "20", H3 = "30", Z = 5)
  p <- make_tiny(rows, tree_text = "(((10,20),30),40,O);")
  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter()
  expect_equal(nrow(f$result), 1)
  expect_equal(f$result$H1, "10")
  expect_equal(f$result$H2, "20")
})

test_that("multi-tree files are rejected with a clear error", {
  tree_text <- "(((A,B),C),D,O);\n(((A,C),B),D,O);"
  p <- make_tiny(tree_text = tree_text)
  expect_error(DStatFilter$new()$loadTree(p$tree, "O"), "exactly one tree")
})

test_that("clear errors for the common mistakes", {
  p <- make_tiny()
  expect_error(DStatFilter$new()$loadTree(p$tree, "nope"), "not a tip")

  bad <- make_tiny(data.frame(H1 = "A", H2 = "B", Z = 1))
  expect_error(DStatFilter$new()$loadTable(bad$table), "needs columns")

  wrong <- make_tiny(data.frame(H1 = "A", H2 = "B", H3 = "zzz", Z = 1,
                                stringsAsFactors = FALSE))
  f <- DStatFilter$new()$loadTree(wrong$tree, "O")$loadTable(wrong$table)
  expect_error(f$filter(), "Names not in tree")

  expect_error(DStatFilter$new()$filter(), "loadTree")
})