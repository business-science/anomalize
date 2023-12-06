# Setup

tq_dloads <- tidyverse_cran_downloads %>%
    dplyr::ungroup() %>%
    dplyr::filter(package == "tidyquant")

tq_dloads_small <- tq_dloads %>%
    dplyr::slice_head(n = 60)

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

    expect_message(freq <- time_frequency(tq_dloads))

    expect_equal(freq, 7)

})

test_that("time_frequency works: period = '1 month'", {

    expect_message(freq <- time_frequency(tq_dloads, period = "1 month"))

    expect_equal(freq, 31)

})

test_that("time_frequency works: period = 5", {

    expect_message(freq <- time_frequency(tq_dloads, period = 5))

    expect_equal(freq, 5)

})



test_that("time_trend works: period = 'auto'", {

    expect_message(trend <- time_trend(tq_dloads))

    expect_equal(trend, 91)

})

test_that("time_trend works: period = '90 days'", {

    expect_message(trend <- time_trend(tq_dloads, period = "30 days"))

    expect_equal(trend, 30)

})

test_that("time_trend works: period = 90", {

    expect_message(trend <- time_trend(tq_dloads, period = 90))

    expect_equal(trend, 90)

})

test_that("time_trend works with small data: period = 'auto'", {

    expect_message(trend <- time_trend(tq_dloads_small))

    expect_equal(trend, 28)

})

