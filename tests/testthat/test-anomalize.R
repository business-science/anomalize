context("test-anomalize.R")

# Setup

library(tidyverse)

tq_dloads <- tidyverse_cran_downloads %>%
    dplyr::ungroup() %>%
    dplyr::filter(package == "tidyquant")

# Tests

test_that("iqr_tbl_df works", {

    iqr_tbl_df <- tq_dloads %>%
        anomalize(count, method = "iqr")

    expect_equal(nrow(iqr_tbl_df), 425)
    expect_equal(ncol(iqr_tbl_df), 6)

})

test_that("gesd_tbl_df works", {

    gesd_tbl_df <- tq_dloads %>%
        anomalize(count, method = "gesd")

    expect_equal(nrow(gesd_tbl_df), 425)
    expect_equal(ncol(gesd_tbl_df), 6)

})

test_that("iqr_grouped_df works", {

    iqr_grouped_df <- tidyverse_cran_downloads %>%
        dplyr::ungroup() %>%
        dplyr::filter(package %in% c("tidyquant", "tidytext")) %>%
        dplyr::group_by(package) %>%
        anomalize(count, method = "iqr")

    expect_equal(nrow(iqr_grouped_df), 850)
    expect_equal(ncol(iqr_grouped_df), 6)

})

test_that("gesd_grouped_df works", {

    gesd_grouped_df <- tidyverse_cran_downloads %>%
        dplyr::ungroup() %>%
        dplyr::filter(package %in% c("tidyquant", "tidytext")) %>%
        dplyr::group_by(package) %>%
        anomalize(count, method = "gesd")

    expect_equal(nrow(gesd_grouped_df), 850)
    expect_equal(ncol(gesd_grouped_df), 6)

})




