context("test-time_frequency.R")

# Setup

tq_dloads <- tidyverse_cran_downloads %>%
    dplyr::ungroup() %>%
    dplyr::filter(package == "tidyquant")

tq_dloads_small <- tq_dloads %>%
    dplyr::slice(1:60)

# Tests

test_that("time_frequency works: period = 'auto'", {

    freq <- tq_dloads %>%
        time_frequency()

    expect_equal(freq, 7)

})

test_that("time_frequency works: period = '2 weeks'", {

    freq <- tq_dloads %>%
        time_frequency(period = "2 weeks")

    expect_equal(freq, 14)

})

test_that("time_frequency works: period = 5", {

    freq <- tq_dloads %>%
        time_frequency(period = 5)

    expect_equal(freq, 5)

})



test_that("time_trend works: period = 'auto'", {

    trend <- tq_dloads %>%
        time_trend()

    expect_equal(trend, 91)

})

test_that("time_trend works: period = '90 days'", {

    trend <- tq_dloads %>%
        time_trend(period = "90 days")

    expect_equal(trend, 90)

})

test_that("time_trend works: period = 90", {

    trend <- tq_dloads %>%
        time_trend(period = 90)

    expect_equal(trend, 90)

})

test_that("time_trend works with small data: period = 'auto'", {

    trend <- tq_dloads_small %>%
        time_trend()

    expect_equal(trend, 28)

})
