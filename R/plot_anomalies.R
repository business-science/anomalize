#' Visualize the anomalies in one or multiple time series
#'
#' @param data A `tibble` or `tbl_time` object.
#' @param time_recomposed A boolean. If `TRUE`, will use the `time_recompose()` bands to
#' place bands as approximate limits around the "normal" data.
#' @param ncol Number of columns to display. Set to 1 for single column by default.
#' @param color_no Color for non-anomalous data.
#' @param color_yes Color for anomalous data.
#' @param fill_ribbon Fill color for the time_recomposed ribbon.
#' @param alpha_dots Controls the transparency of the dots. Reduce when too many dots on the screen.
#' @param alpha_circles Controls the transparency of the circles that identify anomalies.
#' @param alpha_ribbon Controls the transparency of the time_recomposed ribbon.
#' @param size_dots Controls the size of the dots.
#' @param size_circles Controls the size of the circles that identify anomalies.
#'
#' @return Returns a `ggplot` object.
#'
#' @details
#' Plotting function for visualizing anomalies on one or more time series.
#' Multiple time series must be grouped using `dplyr::group_by()`.
#'
#' @seealso [plot_anomaly_decomposition()]
#'
#' @examples
#'
#' library(dplyr)
#' library(ggplot2)
#'
#' data(tidyverse_cran_downloads)
#'
#' #### SINGLE TIME SERIES ####
#' tidyverse_cran_downloads %>%
#'     filter(package == "tidyquant") %>%
#'     ungroup() %>%
#'     time_decompose(count, method = "stl") %>%
#'     anomalize(remainder, method = "iqr") %>%
#'     time_recompose() %>%
#'     plot_anomalies(time_recomposed = TRUE)
#'
#'
#' #### MULTIPLE TIME SERIES ####
#' tidyverse_cran_downloads %>%
#'     time_decompose(count, method = "stl") %>%
#'     anomalize(remainder, method = "iqr") %>%
#'     time_recompose() %>%
#'     plot_anomalies(time_recomposed = TRUE, ncol = 3)
#'
#' @export
plot_anomalies <- function(data, time_recomposed = FALSE, ncol = 1,
                           color_no = "#2c3e50", color_yes = "#e31a1c", fill_ribbon = "grey70",
                           alpha_dots = 1, alpha_circles = 1, alpha_ribbon = 1,
                           size_dots = 1.5, size_circles = 4) {

    UseMethod("plot_anomalies", data)
}

#' @export
plot_anomalies.default <- function(data, time_recomposed = FALSE, ncol = 1,
                                    color_no = "#2c3e50", color_yes = "#e31a1c", fill_ribbon = "grey70",
                                    alpha_dots = 1, alpha_circles = 1, alpha_ribbon = 1,
                                    size_dots = 1.5, size_circles = 4) {
    stop("Object is not of class `tbl_time`.", call. = FALSE)
}

#' @export
plot_anomalies.tbl_time <- function(data, time_recomposed = FALSE, ncol = 1,
                                   color_no = "#2c3e50", color_yes = "#e31a1c", fill_ribbon = "grey70",
                                   alpha_dots = 1, alpha_circles = 1, alpha_ribbon = 1,
                                   size_dots = 1.5, size_circles = 4) {

    # Checks
    column_names <- names(data)
    check_names  <- c("observed", "anomaly") %in% column_names
    if (!all(check_names)) stop('Error in plot_anomalies(): key names are missing. Make sure observed:remainder, anomaly, recomposed_l1, and recomposed_l2 are present', call. = FALSE)

    # Setup
    date_expr  <- tibbletime::get_index_quo(data)
    date_col   <- tibbletime::get_index_char(data)

    g <- data %>%
        ggplot2::ggplot(ggplot2::aes_string(x = date_col, y = "observed"))


    if (time_recomposed) {
        check_names  <- c("recomposed_l1", "recomposed_l2") %in% column_names
        if (!all(check_names)) stop('Error in plot_anomalies(): key names are missing. Make sure recomposed_l1 and recomposed_l2 are present', call. = FALSE)

        g <- g +
            ggplot2::geom_ribbon(ggplot2::aes(ymin = recomposed_l1, ymax = recomposed_l2),
                                 fill = fill_ribbon)

    }

    g <- g +
        ggplot2::geom_point(ggplot2::aes_string(color = "anomaly"), size = size_dots, alpha = alpha_dots) +
        ggplot2::geom_point(ggplot2::aes_string(x = date_col, y = "observed", color = "anomaly"),
                           size = size_circles, shape = 1, alpha = alpha_circles,
                           data = data %>% dplyr::filter(anomaly == "Yes"), 
                           inherit.aes = FALSE) +
        theme_tq() +
        ggplot2::scale_color_manual(values = c("No" = color_no, "Yes" = color_yes)) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))




    if (dplyr::is.grouped_df(data)) {

        facet_group <- dplyr::groups(data) %>%
            purrr::map(quo_name) %>%
            unlist() %>%
            paste0(collapse = " + ")

        g <- g +
            ggplot2::facet_wrap(as.formula(paste0(" ~ ", facet_group)),
                                scales = "free_y", ncol = ncol)
    }

    return(g)

}
