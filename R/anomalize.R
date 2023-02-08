#' Detect anomalies using the tidyverse
#'
#' The `anomalize()` function is used to detect outliers in a distribution
#' with no trend or seasonality present. It takes the output of [time_decompose()],
#' which has be de-trended and applies anomaly detection methods to identify outliers.
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
#' The return has three columns:
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
#' The IQR method is used in [`forecast::tsoutliers()`](https://github.com/robjhyndman/forecast).
#'
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
#' The GESD method is used in [`AnomalyDection::AnomalyDetectionTs()`](https://github.com/twitter/AnomalyDetection).
#'
#' @references
#' 1. [How to correct outliers once detected for time series data forecasting? Cross Validated, https://stats.stackexchange.com](https://stats.stackexchange.com/questions/69874/how-to-correct-outliers-once-detected-for-time-series-data-forecasting)
#' 2. [Cross Validated: Simple algorithm for online outlier detection of a generic time series. Cross Validated, https://stats.stackexchange.com](https://stats.stackexchange.com/questions/1142/simple-algorithm-for-online-outlier-detection-of-a-generic-time-series?)
#' 3. [Owen S. Vallis, Jordan Hochenbaum and Arun Kejariwal (2014).
#' A Novel Technique for Long-Term Anomaly Detection in the Cloud. Twitter Inc.](https://www.usenix.org/system/files/conference/hotcloud14/hotcloud14-vallis.pdf)
#' 4. [Owen S. Vallis, Jordan Hochenbaum and Arun Kejariwal (2014). AnomalyDetection: Anomaly Detection Using
#' Seasonal Hybrid Extreme Studentized Deviate Test. R package version 1.0.](https://github.com/twitter/AnomalyDetection)
#' 5. Alex T.C. Lau (November/December 2015). GESD - A Robust and Effective Technique for Dealing with Multiple Outliers. ASTM Standardization News. www.astm.org/sn
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
#' \dontrun{
#' library(dplyr)
#'
#' # Needed to pass CRAN check / This is loaded by default
#' set_time_scale_template(time_scale_template())
#'
#' data(tidyverse_cran_downloads)
#'
#' tidyverse_cran_downloads %>%
#'     time_decompose(count, method = "stl") %>%
#'     anomalize(remainder, method = "iqr")
#' }
#'
#' @export
anomalize <- function(data, target, method = c("iqr", "gesd"),
                      alpha = 0.05, max_anoms = 0.20, verbose = FALSE) {
    UseMethod("anomalize", data)
}

#' @export
anomalize.default <- function(data, target, method = c("iqr", "gesd"),
                              alpha = 0.05, max_anoms = 0.20, verbose = FALSE) {
    stop("Error anomalize(): Object is not of class `tbl_df` or `tbl_time`.", call. = FALSE)
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

