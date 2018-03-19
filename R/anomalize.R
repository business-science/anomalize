#' Detect anomalies using the tidyverse
#'
#' @inheritParams time_apply
#' @param data A `tibble` or `tbl_time` object.
#' @param method The anomaly detection method. One of `"iqr"` or `"gesd"`.
#' The IQR method is faster at the expense of possibly not being quite as accurate.
#' The GESD method has the best properties for outlier detection, but is loop-based
#' and therefore a bit slower.
#' @param alpha Controls the width of the "normal" range.
#' Lower values are more conservative while higher values are less prone
#' to incorrectly classifying "normal" observations.
#' @param max_anoms The maximum percent of anomalies permitted to be identified.
#' @param verbose A boolean. If `TRUE`, will return a list containing useful information
#' about the anomalies. If `FALSE`, just returns the data expanded with the anomalies and
#' the lower (l1) and upper (l2) bounds.
#'
#' @return Returns a `tibble` / `tbl_time` object or list depending on the value of `verbose`.
#'
#' @details
#' The `anomalize()` function is used to detect outliers in a distribution
#' with no trend or seasonality present. The return has three columns:
#' "remainder_l1" (lower limit for anomalies), "remainder_l2" (upper limit for
#' anomalies), and "anomaly" (Yes/No).
#'
#' Use [time_decompose()] to decompose a time series prior to performing
#' anomaly detection with `anomalize()`.  Typically, `anomalize()` is
#' performed on the "remainder" of the time series decomposition.
#'
#' For non-time series data (data without trend), the `anomalize()` function can
#' be used without time series decomposition.
#'
#' The `anomalize()` function uses two methods for outlier detection
#' each with benefits.
#'
#' __IQR__:
#'
#' The IQR Method uses an innerquartile range of 25% and 75% to establish a baseline distribution around
#' the median. With the default `alpha = 0.05`, the limits are established by expanding
#' the 25/75 baseline by an IQR Factor of 3 (3X). The IQR Factor = 0.15 / alpha (hense 3X with alpha = 0.05).
#' To increase the IQR Factor controling the limits, decrease the alpha, which makes
#' it more difficult to be an outlier. Increase alpha to make it easier to be an outlier.
#'
#' __GESD__:
#'
#' The GESD Method (Generlized Extreme Studentized Deviate Test) progressively
#' eliminates outliers using a Student's T-Test comparing the test statistic to a critical value.
#' Each time an outlier is removed, the test statistic is updated. Once test statistic
#' drops below the critical value, all outliers are considered removed. Because this method
#' involves continuous updating via a loop, it is slower than the IQR method. However, it
#' tends to be the best performing method for outlier removal.
#'
#' @seealso
#' Anomaly Detection Methods (Powers `anomalize`)
#' - [iqr()]
#' - [gesd()]
#'
#' Time Series Anomaly Detection Functions (anomaly detection workflow):
#' - [time_decompose()]
#' - [time_recompose()]
#'
#' @examples
#'
#' library(dplyr)
#'
#' data(tidyverse_cran_downloads)
#'
#' tidyverse_cran_downloads %>%
#'     time_decompose(count, method = "stl") %>%
#'     anomalize(remainder, method = "iqr")
#'
#' @references
#' - The IQR method is used in [`forecast::tsoutliers()`](https://github.com/robjhyndman/forecast/blob/master/R/clean.R)
#' - The GESD method is used in Twitter's [`AnomalyDetection`](https://github.com/twitter/AnomalyDetection) package and is also available as a function in [@raunakms's GESD method](https://github.com/raunakms/GESD/blob/master/runGESD.R)
#'
#' @export
anomalize <- function(data, target, method = c("iqr", "gesd"),
                      alpha = 0.05, max_anoms = 0.20, verbose = FALSE) {
    UseMethod("anomalize", data)
}

#' @export
anomalize.default <- function(data, target, method = c("iqr", "gesd"),
                              alpha = 0.05, max_anoms = 0.20, verbose = FALSE) {
    stop("Object is not of class `tbl_df` or `tbl_time`.", call. = FALSE)
}

#' @export
anomalize.tbl_df <- function(data, target, method = c("iqr", "gesd"),
                      alpha = 0.05, max_anoms = 0.20, verbose = FALSE) {

    # Checks
    if (missing(target)) stop('Error in anomalize(): argument "target" is missing, with no default', call. = FALSE)

    # Setup
    target_expr <- rlang::enquo(target)

    method <- tolower(method[[1]])
    x      <- data %>% dplyr::pull(!! target_expr)

    # Detect Anomalies
    # method <- tolower(method[[1]])
    # args   <- list(x         = data %>% dplyr::pull(!! target_expr),
    #                alpha     = alpha,
    #                max_anoms = max_anoms,
    #                verbose   = TRUE)
    #
    # outlier_list <- do.call(method, args)

    # Explicitly call functions
    if (method == "iqr") {
        outlier_list <- anomalize::iqr(x         = x,
                                       alpha     = alpha,
                                       max_anoms = max_anoms,
                                       verbose   = TRUE)
    } else if (method == "gesd") {
        outlier_list <- anomalize::gesd(x         = x,
                                        alpha     = alpha,
                                        max_anoms = max_anoms,
                                        verbose   = TRUE)

    } else {
        stop("The `method` selected is invalid.", call. = FALSE)
    }

    outlier      <- outlier_list$outlier
    limit_lower  <- outlier_list$critical_limits[[1]]
    limit_upper  <- outlier_list$critical_limits[[2]]

    # Returns
    ret <- data %>%
        dplyr::mutate(!! paste0(dplyr::quo_name(target_expr), "_l1") := limit_lower,
                      !! paste0(dplyr::quo_name(target_expr), "_l2") := limit_upper) %>%
        tibble::add_column(anomaly = outlier)

    if (verbose) {
        ret <- list(
            anomalized_tbl       = ret,
            anomaly_details      = outlier_list
        )

        return(ret)

    } else {
        return(ret)
    }

}

#' @export
anomalize.grouped_df <- function(data, target, method = c("iqr", "gesd"),
                                 alpha = 0.05, max_anoms = 0.20, verbose = FALSE, ...) {

    # Checks
    if (missing(target)) stop('Error in anomalize(): argument "target" is missing, with no default', call. = FALSE)
    if (verbose) warning(glue::glue("Cannot use 'verbose = TRUE' with grouped data."))

    # Setup
    target_expr <- dplyr::enquo(target)

    ret <- data %>%
        grouped_mapper(
            .f        = anomalize,
            target    = !! target_expr,
            method    = method[[1]],
            alpha     = alpha,
            max_anoms = max_anoms,
            verbose   = F,
            ...)

    return(ret)

}

