test_that("errors on incorrect input", {
    expect_error(plot_anomaly_decomposition(3))
})

test_that("returns a ggplot", {
    g <- tidyverse_cran_downloads %>%
        dplyr::filter(package == "tidyquant") %>%
        dplyr::ungroup() %>%
        time_decompose(count, method = "stl") %>%
        anomalize(remainder, method = "iqr") %>%
        plot_anomaly_decomposition()

    expect_s3_class(g, "ggplot")
})
