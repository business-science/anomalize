context("test-time_frequency.R")

# Setup

tq_dloads <- tidyverse_cran_downloads %>%
    ungroup() %>%
    filter(package == "tidyquant")

tq_dloads_small <- tq_dloads %>%
    slice(1:60)

# Tests

test_that("time_frequency fails with incorrect input", {
    expect_error(time_frequency(5))
    expect_error(time_frequency(tidyverse_cran_downloads))
})

test_that("time_trend fails with incorrect input", {
    expect_error(time_trend(5))
    expect_error(time_trend(tidyverse_cran_downloads))
})

test_that("time_frequency works: period = 'auto'", {

    freq <- tq_dloads %>%
        time_frequency()

    expect_equal(freq, 7)

})

test_that("time_frequency works: period = '1 month'", {

    freq <- tq_dloads %>%
        time_frequency(period = "1 month")

    expect_equal(freq, 31)

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
        time_trend(period = "30 days")

    expect_equal(trend, 30)

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

