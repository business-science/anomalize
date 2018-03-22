context("test-plot_anomalies.R")

test_that("errors on incorrect input", {
  expect_error(plot_anomalies(3))
})

test_that("returns a ggplot", {
    g <- tidyverse_cran_downloads %>%
        time_decompose(count, method = "stl") %>%
        anomalize(remainder, method = "iqr") %>%
        time_recompose() %>%
        plot_anomalies(time_recomposed = TRUE, ncol = 3)
    expect_s3_class(g, "ggplot")
})
