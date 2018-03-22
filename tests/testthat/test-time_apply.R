context("test-time_apply.R")


test_that("errors on incorrect input", {
    expect_error(time_apply(2))
    expect_error(tidyverse_cran_downloads %>% time_apply())
})


test_that("grouped_tbl_time works", {
    grouped_tbl_time_mean <- tidyverse_cran_downloads %>%
        time_apply(count, period = "1 week", .fun = mean, na.rm = TRUE)
    expect_equal(ncol(grouped_tbl_time_mean), 4)
})

test_that("tbl_time works", {
    grouped_tbl_time_mean <- tidyverse_cran_downloads %>%
        filter(package == "tidyquant") %>%
        ungroup() %>%
        time_apply(count, period = "1 week", .fun = mean, na.rm = TRUE)
    expect_equal(ncol(grouped_tbl_time_mean), 4)
})

