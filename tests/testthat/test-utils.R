context("test-utils.R")

test_that("utils: time_decompose `merge = T` works", {
    merged_decomposition <- tidyverse_cran_downloads %>%
        time_decompose(count, merge = T)
    expect_equal(ncol(merged_decomposition), 7)
})
