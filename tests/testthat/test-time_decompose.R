context("test-time_decompose.R")


test_that("Incorrect data type errors", {
    expect_error(time_decompose(5))
})

test_that("No target errors", {
    expect_error(time_decompose(tidyverse_cran_downloads))
    expect_error(time_decompose(ungroup(tidyverse_cran_downloads)))
})

test_that("single tbl_df", {
    stl_tbl_time <- tidyverse_cran_downloads %>%
        filter(package == "lubridate") %>%
        ungroup() %>%
        as_tibble() %>%
        time_decompose(count, method = "stl", frequency = "auto", trend = "auto")

    expect_equal(ncol(stl_tbl_time), 5)
    expect_equal(nrow(stl_tbl_time), 425)

})

test_that("grouped tbl_df", {
    stl_tbl_time <- tidyverse_cran_downloads %>%
        as_tibble() %>%
        time_decompose(count, method = "stl", frequency = "auto", trend = "auto")

    expect_equal(ncol(stl_tbl_time), 6)
    expect_equal(nrow(stl_tbl_time), 6375)

})

test_that("method = stl, auto freq/trend", {
    stl_tbl_time <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "stl", frequency = "auto", trend = "auto")

    expect_equal(ncol(stl_tbl_time), 6)
    expect_equal(nrow(stl_tbl_time), 6375)
    expect_equal(group_size(stl_tbl_time) %>% length(), 15)

})

test_that("method = stl, character freq/trend", {
    stl_tbl_time <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "stl", frequency = "1 month", trend = "3 months")

    expect_equal(ncol(stl_tbl_time), 6)
    expect_equal(nrow(stl_tbl_time), 6375)
    expect_equal(group_size(stl_tbl_time) %>% length(), 15)

})

test_that("method = stl, numeric freq/trend", {
    stl_tbl_time <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "stl", frequency = 7, trend = 30)

    expect_equal(ncol(stl_tbl_time), 6)
    expect_equal(nrow(stl_tbl_time), 6375)
    expect_equal(group_size(stl_tbl_time) %>% length(), 15)

})

test_that("method = twitter, auto freq/trend", {
    twitter_tbl_time <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "twitter", frequency = "auto", trend = "auto")

    expect_equal(ncol(twitter_tbl_time), 6)
    expect_equal(nrow(twitter_tbl_time), 6375)
    expect_equal(group_size(twitter_tbl_time) %>% length(), 15)

})

test_that("method = twitter, character freq/trend", {
    twitter_tbl_time <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "twitter", frequency = "1 week", trend = "1 month")

    expect_equal(ncol(twitter_tbl_time), 6)
    expect_equal(nrow(twitter_tbl_time), 6375)
    expect_equal(group_size(twitter_tbl_time) %>% length(), 15)

})

test_that("method = twitter, numeric freq/trend", {
    twitter_tbl_time <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "twitter", frequency = 7, trend = 90)

    expect_equal(ncol(twitter_tbl_time), 6)
    expect_equal(nrow(twitter_tbl_time), 6375)
    expect_equal(group_size(twitter_tbl_time) %>% length(), 15)

})

# test_that("method = multiplicative, auto freq/trend", {
#     mult_tbl_time <- tidyverse_cran_downloads %>%
#         time_decompose(count, method = "multiplicative", frequency = "auto", trend = "auto")
#
#     expect_equal(ncol(mult_tbl_time), 6)
#     expect_equal(nrow(mult_tbl_time), 6375)
#     expect_equal(group_size(mult_tbl_time) %>% length(), 15)
#
# })
#
# test_that("method = multiplicative, character freq/trend", {
#     mult_tbl_time <- tidyverse_cran_downloads %>%
#         time_decompose(count, method = "multiplicative", frequency = "1 week", trend = "1 month")
#
#     expect_equal(ncol(mult_tbl_time), 6)
#     expect_equal(nrow(mult_tbl_time), 6375)
#     expect_equal(group_size(mult_tbl_time) %>% length(), 15)
#
# })
#
# test_that("method = multiplicative, numeric freq/trend", {
#     mult_tbl_time <- tidyverse_cran_downloads %>%
#         time_decompose(count, method = "multiplicative", frequency = 7, trend = 90)
#
#     expect_equal(ncol(mult_tbl_time), 6)
#     expect_equal(nrow(mult_tbl_time), 6375)
#     expect_equal(group_size(mult_tbl_time) %>% length(), 15)
#
# })

test_that("grouped_df works", {
    grouped_data <- tidyverse_cran_downloads %>%
        as_tibble() %>%
        time_decompose(count)

    expect_equal(ncol(grouped_data), 6)
    expect_equal(nrow(grouped_data), 6375)
    expect_equal(group_size(grouped_data) %>% length(), 15)

})
