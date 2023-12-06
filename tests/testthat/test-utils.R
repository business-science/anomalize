test_that("utils: time_decompose `merge = TRUE` works", {
    merged_decomposition <- tidyverse_cran_downloads %>%
        time_decompose(count, merge = TRUE)
    expect_equal(ncol(merged_decomposition), 7)
})
