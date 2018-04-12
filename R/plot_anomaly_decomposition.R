#' Visualize the time series decomposition with anomalies shown
#'
#' @param data A `tibble` or `tbl_time` object.
#' @param ncol Number of columns to display. Set to 1 for single column by default.
#' @param color_no Color for non-anomalous data.
#' @param color_yes Color for anomalous data.
#' @param alpha_dots Controls the transparency of the dots. Reduce when too many dots on the screen.
#' @param alpha_circles Controls the transparency of the circles that identify anomalies.
#' @param size_dots Controls the size of the dots.
#' @param size_circles Controls the size of the circles that identify anomalies.
#' @param strip.position Controls the placement of the strip that identifies the time series decomposition components.
#'
#' @return Returns a `ggplot` object.
#'
#' @details
#' The first step in reviewing the anomaly detection process is to evaluate
#' a single times series to observe how the algorithm is selecting anomalies.
#' The `plot_anomaly_decomposition()` function is used to gain
#' an understanding as to whether or not the method is detecting anomalies correctly and
#' whether or not parameters such as decomposition method, anomalize method,
#' alpha, frequency, and so on should be adjusted.
#'
#' @seealso [plot_anomalies()]
#'
#' @examples
#'
#' library(dplyr)
#' library(ggplot2)
#'
#' data(tidyverse_cran_downloads)
#'
#' tidyverse_cran_downloads %>%
#'     filter(package == "tidyquant") %>%
#'     ungroup() %>%
#'     time_decompose(count, method = "stl") %>%
#'     anomalize(remainder, method = "iqr") %>%
#'     plot_anomaly_decomposition()
#'
#' @export
plot_anomaly_decomposition <- function(data, ncol = 1, color_no = "#2c3e50", color_yes = "#e31a1c",
                                       alpha_dots = 1, alpha_circles = 1, size_dots = 1.5, size_circles = 4,
                                       strip.position = "right") {
    UseMethod("plot_anomaly_decomposition", data)

}

#' @export
plot_anomaly_decomposition.default <- function(data, ncol = 1, color_no = "#2c3e50", color_yes = "#e31a1c",
                                               alpha_dots = 1, alpha_circles = 1, size_dots = 1.5, size_circles = 4,
                                               strip.position = "right") {
    stop("Object is not of class `tbl_time`.", call. = FALSE)


}

#' @export
plot_anomaly_decomposition.grouped_tbl_time <- function(data, ncol = 1, color_no = "#2c3e50", color_yes = "#e31a1c",
                                               alpha_dots = 1, alpha_circles = 1, size_dots = 1.5, size_circles = 4,
                                               strip.position = "right") {
    stop("Object cannot be grouped. Select a single time series for evaluation, and use `dplyr::ungroup()`.", call. = FALSE)


}

#' @export
plot_anomaly_decomposition.tbl_time <- function(data, ncol = 1, color_no = "#2c3e50", color_yes = "#e31a1c",
                                                alpha_dots = 1, alpha_circles = 1, size_dots = 1.5, size_circles = 4,
                                                strip.position = "right") {

    # Checks
    column_names <- names(data)
    check_names <- c("observed", "remainder", "anomaly", "remainder_l1", "remainder_l2") %in% column_names
    if (!all(check_names)) stop('Error in plot_anomaly_decomposition(): key names are missing. Make sure observed:remainder, remainder_l1, and remainder_l2 are present', call. = FALSE)


    # Setup
    date_expr  <- tibbletime::get_index_quo(data)
    date_col   <- tibbletime::get_index_char(data)

    data_anomaly_tbl <- data %>%
        dplyr::select(!! date_expr, observed:remainder, anomaly) %>%
        tidyr::gather(key = key, value = value, -dplyr::one_of(c(!! date_col, 'anomaly')), factor_key = T)

    g <- data_anomaly_tbl  %>%
        ggplot2::ggplot(ggplot2::aes_string(x = date_col, y = "value", color = "anomaly")) +
        # Points
        ggplot2::geom_point(size = size_dots, alpha = alpha_dots) +
        # Circles
        ggplot2::geom_point(size = size_circles, shape = 1, alpha = alpha_circles,
                   data = data_anomaly_tbl %>% dplyr::filter(anomaly == "Yes")) +
        # Horizontal Line at Y = 0
        ggplot2::geom_hline(yintercept = 0, color = palette_light()[[1]]) +
        theme_tq() +
        ggplot2::facet_wrap(~ key, ncol = ncol, scales = "free_y", strip.position = strip.position) +
        ggplot2::scale_color_manual(values = c("No" = color_no, "Yes" = color_yes)) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))


    return(g)

}
