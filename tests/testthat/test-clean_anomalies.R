

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

    expect_true(data_stl %>%
                    clean_anomalies() %>%
                    names() %>%
                    str_detect("observed_cleaned") %>%
                    any())

})

test_that("Clean Anomalies from Twitter Method", {

    expect_true(data_twitter %>%
                    clean_anomalies() %>%
                    names() %>%
                    str_detect("observed_cleaned") %>%
                    any())

})
