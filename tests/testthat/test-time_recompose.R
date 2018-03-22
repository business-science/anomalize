context("test-time_recompose.R")


test_that("errors on incorrect input", {
  expect_error(time_recompose(5))
})

test_that("time_recompose works on grouped_tbl_time", {
    grouped_recomp <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "stl") %>%
        anomalize(remainder, method = "iqr") %>%
        time_recompose()
    expect_true("recomposed_l2" %in% names(grouped_recomp))
})

test_that("time_recompose works on tbl_time", {
    single_recomp <- tidyverse_cran_downloads %>%
        filter(package == "tidyquant") %>%
        ungroup() %>%
        time_decompose(count, method = "stl") %>%
        anomalize(remainder, method = "iqr") %>%
        time_recompose()
    expect_true("recomposed_l2" %in% names(single_recomp))
})

