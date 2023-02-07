#' Decompose a time series in preparation for anomaly detection
#'
#' @inheritParams anomalize
#' @param data A `tibble` or `tbl_time` object.
#' @param method The time series decomposition method. One of `"stl"` or `"twitter"`.
#' The STL method uses seasonal decomposition (see [decompose_stl()]).
#' The Twitter method uses `trend` to remove the trend (see [decompose_twitter()]).
#' @param frequency Controls the seasonal adjustment (removal of seasonality).
#' Input can be either "auto", a time-based definition (e.g. "1 week"),
#' or a numeric number of observations per frequency (e.g. 10).
#' Refer to [time_frequency()].
#' @param trend Controls the trend component
#' For stl, the trend controls the sensitivity of the lowess smoother, which is used to remove the remainder.
#' For twitter, the trend controls the period width of the median, which are used to remove the trend and center the remainder.
#' @param ... Additional parameters passed to the underlying method functions.
#' @param merge A boolean. `FALSE` by default. If `TRUE`, will append results to the original data.
#' @param message A boolean. If `TRUE`, will output information related to `tbl_time` conversions, frequencies,
#' and trend / median spans (if applicable).
#'
#' @return Returns a `tbl_time` object.
#'
#' @details
#' The `time_decompose()` function generates a time series decomposition on
#' `tbl_time` objects. The function is "tidy" in the sense that it works
#' on data frames. It is designed to work with time-based data, and as such
#' must have a column that contains date or datetime information. The function
#' also works with grouped data. The function implements several methods
#' of time series decomposition, each with benefits.
#'
#' __STL__:
#'
#' The STL method (`method = "stl"`) implements time series decomposition using
#' the underlying [decompose_stl()] function. If you are familiar with [stats::stl()],
#' the function is a "tidy" version that is designed to work with `tbl_time` objects.
#' The decomposition separates the "season" and "trend" components from
#' the "observed" values leaving the "remainder" for anomaly detection.
#' The user can control two parameters: `frequency` and `trend`.
#' The `frequency` parameter adjusts the "season" component that is removed
#' from the "observed" values. The `trend` parameter adjusts the
#' trend window (`t.window` parameter from `stl()`) that is used.
#' The user may supply both `frequency`
#' and `trend` as time-based durations (e.g. "90 days") or numeric values
#' (e.g. 180) or "auto", which predetermines the frequency and/or trend
#' based on the scale of the time series.
#'
#'
#' __Twitter__:
#'
#' The Twitter method (`method = "twitter"`) implements time series decomposition using
#' the methodology from the Twitter [AnomalyDetection](https://github.com/twitter/AnomalyDetection) package.
#' The decomposition separates the "seasonal" component and then removes
#' the median data, which is a different approach than the STL method for removing
#' the trend. This approach works very well for low-growth + high seasonality data.
#' STL may be a better approach when trend is a large factor.
#' The user can control two parameters: `frequency` and `trend`.
#' The `frequency` parameter adjusts the "season" component that is removed
#' from the "observed" values. The `trend` parameter adjusts the
#' period width of the median spans that are used. The user may supply both `frequency`
#' and `trend` as time-based durations (e.g. "90 days") or numeric values
#' (e.g. 180) or "auto", which predetermines the frequency and/or median spans
#' based on the scale of the time series.
#'
#' @references
#' 1. CLEVELAND, R. B., CLEVELAND, W. S., MCRAE, J. E., AND TERPENNING, I.
#' STL: A Seasonal-Trend Decomposition Procedure Based on Loess. Journal of Official Statistics, Vol. 6, No. 1 (1990), pp. 3-73.
#' 2. [Owen S. Vallis, Jordan Hochenbaum and Arun Kejariwal (2014).
#' A Novel Technique for Long-Term Anomaly Detection in the Cloud. Twitter Inc.](https://www.usenix.org/system/files/conference/hotcloud14/hotcloud14-vallis.pdf)
#' 3. [Owen S. Vallis, Jordan Hochenbaum and Arun Kejariwal (2014). AnomalyDetection: Anomaly Detection Using
#' Seasonal Hybrid Extreme Studentized Deviate Test. R package version 1.0.](https://github.com/twitter/AnomalyDetection)
#'
#' @seealso
#' Decomposition Methods (Powers `time_decompose`)
#' - [decompose_stl()]
#' - [decompose_twitter()]
#'
#' Time Series Anomaly Detection Functions (anomaly detection workflow):
#' - [anomalize()]
#' - [time_recompose()]
#'
#' @examples
#'
#' library(dplyr)
#'
#' data(tidyverse_cran_downloads)
#'
#' # Basic Usage
#' tidyverse_cran_downloads %>%
#'     time_decompose(count, method = "stl")
#'
#' # twitter
#' tidyverse_cran_downloads %>%
#'     time_decompose(count,
#'                    method       = "twitter",
#'                    frequency    = "1 week",
#'                    trend        = "2 months",
#'                    merge        = TRUE,
#'                    message      = FALSE)
#'
#' @export
time_decompose <- function(data, target, method = c("stl", "twitter"),
                           frequency = "auto", trend = "auto", ..., merge = FALSE, message = TRUE) {
    UseMethod("time_decompose", data)
}

#' @export
time_decompose.default <- function(data, target, method = c("stl", "twitter"),
                                   frequency = "auto", trend = "auto", ..., merge = FALSE, message = TRUE) {
    stop("Error time_decompose(): Object is not of class `tbl_df` or `tbl_time`.", call. = FALSE)
}

#' @export
time_decompose.tbl_time <- function(data, target, method = c("stl", "twitter"),
                                    frequency = "auto", trend = "auto", ..., merge = FALSE, message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in time_decompose(): argument "target" is missing, with no default', call. = FALSE)

    # Setup
    target_expr <- dplyr::enquo(target)
    method      <- tolower(method[[1]])

    # Set method
    if (method == "twitter") {
        decomp_tbl <- data %>%
            decompose_twitter(!! target_expr, frequency = frequency, trend = trend, message = message, ...)
    } else if (method == "stl") {
        decomp_tbl <- data %>%
            decompose_stl(!! target_expr, frequency = frequency, trend = trend, message = message, ...)
    # } else if (method == "multiplicative") {
    #     decomp_tbl <- data %>%
    #         decompose_multiplicative(!! target_expr, frequency = frequency, message = message, ...)
    } else {
        stop(paste0("method = '", method[[1]], "' is not a valid option."))
    }

    # Merge if desired
    if (merge) {
        ret <- merge_two_tibbles(data, decomp_tbl, .f = time_decompose)
    } else {
        ret <- decomp_tbl
    }

    return(ret)

}

#' @export
time_decompose.tbl_df <- function(data, target, method = c("stl", "twitter"),
                                  frequency = "auto", trend = "auto", ..., merge = FALSE, message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in time_decompose(): argument "target" is missing, with no default', call. = FALSE)

    # Prep
    data <- prep_tbl_time(data, message = message)

    # Send to time_decompose.tbl_time
    time_decompose(data      = data,
                   target    = !! dplyr::enquo(target),
                   method    = method[[1]],
                   frequency = frequency,
                   trend     = trend,
                   ...       = ...,
                   merge     = merge,
                   message   = message)

}




#' @export
time_decompose.grouped_tbl_time <- function(data, target, method = c("stl", "twitter"),
                                            frequency = "auto", trend = "auto", ..., merge = FALSE, message = FALSE) {

    # Checks
    if (missing(target)) stop('Error in time_decompose(): argument "target" is missing, with no default', call. = FALSE)

    # Setup
    target_expr <- dplyr::enquo(target)

    # Mapping
    ret <- data %>%
        grouped_mapper(
            .f        = time_decompose,
            target    = !! target_expr,
            method    = method[[1]],
            frequency = frequency,
            trend     = trend,
            ...       = ...,
            merge     = merge,
            message   = message)

    return(ret)

}

#' @export
time_decompose.grouped_df <- function(data, target, method = c("stl", "twitter"),
                                      frequency = "auto", trend = "auto", ..., merge = FALSE, message = FALSE) {

    data <- prep_tbl_time(data, message = message)

    # Send to grouped_tbl_time
    time_decompose(data      = data,
                   target    = !! dplyr::enquo(target),
                   method    = method[[1]],
                   frequency = frequency,
                   trend     = trend,
                   ...       = ...,
                   merge     = merge,
                   message   = message)

}


