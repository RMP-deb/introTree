# Core tests for introTree.


# Writes a tiny tree and table to temporary files and returns their paths.
# Tree: ((((A,B),C),D),O) once rooted on O.
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

test_that("filter keeps, sorts, and marks tree-congruent rows", {
  p <- make_tiny()
  on.exit(unlink(c(p$tree, p$table)), add = TRUE)

  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter(
    z_threshold = 4)

  expect_equal(nrow(f$result), 2)
  expect_true(all(f$result$congruent))
  expect_true(all(f$result$H1 == "A" & f$result$H2 == "B"))
  expect_equal(f$result$abs_Z, c(4.2, 3.8))
  expect_equal(f$result$significant, c(TRUE, FALSE))
  expect_true("p_adj" %in% names(f$result))
  expect_false(any(f$result$H1 == "A" & f$result$H2 == "B" &
                     f$result$H3 == "O"))
})

test_that("filter returns an empty result when no rows are congruent", {
  rows <- data.frame(H1 = "A", H2 = "C", H3 = "B", Z = 5)
  p <- make_tiny(rows)
  on.exit(unlink(c(p$tree, p$table)), add = TRUE)

  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter()

  expect_equal(nrow(f$result), 0)
  expect_true(all(c("congruent", "abs_Z", "p", "p_adj", "significant") %in%
                    names(f$result)))
})

test_that("loadTable renames Dsuite columns", {
  rows <- data.frame(P1 = c("A", "A"), P2 = c("B", "B"), P3 = c("C", "D"),
                     `Z-score` = c(4.2, -3.8), check.names = FALSE)
  p <- make_tiny(rows)
  on.exit(unlink(c(p$tree, p$table)), add = TRUE)

  f <- DStatFilter$new()$loadTable(p$table)

  expect_true(all(c("H1", "H2", "H3", "Z") %in% names(f$data)))
  expect_false(any(c("P1", "P2", "P3", "Z-score") %in% names(f$data)))
  expect_equal(f$data$Z, c(4.2, -3.8))
})

test_that("filter excludes missing Z values", {
  rows <- data.frame(H1 = c("A", "A"), H2 = c("B", "B"), H3 = c("C", "C"),
                     Z = c(NA_real_, 5))
  p <- make_tiny(rows)
  on.exit(unlink(c(p$tree, p$table)), add = TRUE)

  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter()

  expect_equal(nrow(f$result), 1)
  expect_false(anyNA(f$result$Z))
  expect_equal(f$result$Z, 5)
})

test_that("loadTable treats numeric species names as character labels", {
  rows <- data.frame(H1 = "10", H2 = "20", H3 = "30", Z = 5)
  p <- make_tiny(rows, tree_text = "(((10,20),30),40,O);")
  on.exit(unlink(c(p$tree, p$table)), add = TRUE)

  f <- DStatFilter$new()$loadTable(p$table)

  expect_type(f$data$H1, "character")
  expect_equal(f$data$H1, "10")
  expect_equal(f$data$H2, "20")
  expect_equal(f$data$H3, "30")
})

test_that("loadTable rejects missing required columns", {
  p <- make_tiny(data.frame(H1 = "A", H2 = "B", Z = 1))
  on.exit(unlink(c(p$tree, p$table)), add = TRUE)

  expect_error(DStatFilter$new()$loadTable(p$table), "needs columns")
})

test_that("loadTree rejects unknown outgroups and multi-tree files", {
  p <- make_tiny()
  multi <- make_tiny(tree_text = "(((A,B),C),D,O);\n(((A,C),B),D,O);")
  on.exit(unlink(c(p$tree, p$table, multi$tree, multi$table)), add = TRUE)

  expect_error(DStatFilter$new()$loadTree(p$tree, "nope"), "not a tip")
  expect_error(DStatFilter$new()$loadTree(multi$tree, "O"), "exactly one tree")
})

test_that("filter rejects names absent from the tree and requires loadTree", {
  p <- make_tiny()
  wrong <- make_tiny(data.frame(H1 = "A", H2 = "B", H3 = "zzz", Z = 1))
  on.exit(unlink(c(p$tree, p$table, wrong$tree, wrong$table)), add = TRUE)

  f <- DStatFilter$new()$loadTree(wrong$tree, "O")$loadTable(wrong$table)
  expect_error(f$filter(), "Names not in tree")
  expect_error(DStatFilter$new()$filter(), "loadTree")
})

test_that("saveResult writes the result and its message can be suppressed", {
  p <- make_tiny()
  out <- tempfile(fileext = ".csv")
  on.exit(unlink(c(p$tree, p$table, out)), add = TRUE)
  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter()

  messages <- character()
  withCallingHandlers(
    f$saveResult(out),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )

  expect_true(file.exists(out))
  expect_equal(nrow(read.csv(out)), nrow(f$result))
  expect_match(messages, "Saved 2 rows")
})

test_that("show prints an object summary", {
  p <- make_tiny()
  on.exit(unlink(c(p$tree, p$table)), add = TRUE)
  f <- DStatFilter$new()$loadTree(p$tree, "O")$loadTable(p$table)$filter()

  expect_output(print(f), "DStatFilter object")
})
