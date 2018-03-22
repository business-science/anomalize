context("test-prep_tbl_time.R")

test_that("prep_tbl_time errors on incorrect input", {
    expect_error(prep_tbl_time(1))
    expect_error(prep_tbl_time(tibble(x = stats::rnorm(100))))
})

test_that("converts tibble to tbl_time", {
    data_tbl <- tibble(
        date  = seq.Date(from = as.Date("2018-01-01"), by = "day", length.out = 10),
        value = rnorm(10)
    )

    expect_s3_class(prep_tbl_time(data_tbl), class = "tbl_time")
    expect_message(prep_tbl_time(data_tbl, message = T))
})

test_that("tbl_time returns tbl_time", {
    data_tbl <- tibble(
        date  = seq.Date(from = as.Date("2018-01-01"), by = "day", length.out = 10),
        value = rnorm(10)
    ) %>%
        tibbletime::as_tbl_time(date)

    expect_s3_class(prep_tbl_time(data_tbl), class = "tbl_time")

})
