

data_stl <- tidyverse_cran_downloads %>%
    time_decompose(count, method = "stl") %>%
    anomalize(remainder, method = "iqr")

data_twitter <- tidyverse_cran_downloads %>%
    time_decompose(count, method = "twitter") %>%
    anomalize(remainder, method = "iqr")


test_that("bad data returns error", {

    expect_error(clean_anomalies(2))

})

test_that("Clean Anomalies from STL Method", {
    expect_match(names(clean_anomalies(data_stl)), "observed_cleaned", all = FALSE)
})

test_that("Clean Anomalies from Twitter Method", {
    expect_match(names(clean_anomalies(data_twitter)), "observed_cleaned", all = FALSE)
})
