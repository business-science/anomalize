context("test-plot_anomaly_decomposition.R")

library(dplyr)
library(ggplot2)

test_that("errors on incorrect input", {
    expect_error(plot_anomaly_decomposition(3))
})

test_that("returns a ggplot", {
    g <- tidyverse_cran_downloads %>%
        filter(package == "tidyquant") %>%
        ungroup() %>%
        time_decompose(count, method = "stl") %>%
        anomalize(remainder, method = "iqr") %>%
        plot_anomaly_decomposition()

    expect_s3_class(g, "ggplot")
})
