#' Decompose a time series in preparation for anomaly detection
#'
#' @inheritParams anomalize
#' @param data A `tibble` or `tbl_time` object.
#' @param method The time series decomposition method. One of `"stl"`, `"twitter"`, or
#' `"multiplicative"`. The STL method uses seasonal decomposition (see [decompose_stl()]).
#' The Twitter method uses `median_spans` to remove the trend (see [decompose_twitter()]).
#' The Multiplicative method uses multiplicative decomposition (see [decompose_multiplicative()]).
#' @param frequency Controls the seasonal adjustment (removal of seasonality).
#' Input can be either "auto", a time-based definition (e.g. "2 weeks"),
#' or a numeric number of observations per frequency (e.g. 10).
#' Refer to [time_frequency()].
#' @param ... Additional parameters passed to the underlying method functions.
#' @param merge A boolean. `FALSE` by default. If `TRUE`, will append results to the original data.
#' @param message A boolean. If `TRUE`, will output information related to `tbl_time` conversions, frequencies,
#' and median spans (if applicable).
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
#' The main parameter that controls the seasonal adjustment is `frequency`.
#' Setting `frequency = "auto"` will lets the [time_frequency()] function
#' automatically determine the frequency based on the scale of the time series.
#'
#' __Twitter__:
#'
#' The Twitter method (`method = "twitter"`) implements time series decomposition using
#' the methodology from the Twitter [AnomalyDetection](https://github.com/twitter/AnomalyDetection) package.
#' The decomposition separates the "seasonal" component and then removes
#' the median data, which is a different approach than the STL method for removing
#' the trend. This approach works very well for low-growth + high seasonality data.
#' STL may be a better approach when trend is a large factor.
#' The user can control two parameters: `frequency` and `median_spans`.
#' The `frequency` parameter adjusts the "season" component that is removed
#' from the "observed" values. The `median_spans` parameter adjusts the
#' number of median spans that are used. The user may supply both `frequency`
#' and `median_spans` as time-based durations (e.g. "6 weeks") or numeric values
#' (e.g. 180) or "auto", which predetermines the frequency and/or median spans
#' based on the scale of the time series.
#'
#' __Multiplicative__:
#'
#' The Multiplicative method (`method = "multiplicative"`) time series decomposition
#' uses the [stats::decompose()] function with `type = "multiplicative"`. This
#' method is useful in circumstances where variance is non-constantant and typically
#' growing in a multiplicative fashion. The parameters are the same as the STL method.
#' Alternatively, users may wish to try a transformation (e.g. `log()` or `sqrt()`) in combination
#' with the STL method to get near-constant variance.
#'
#' @seealso
#' Decomposition Methods (Powers `time_decompose`)
#' - [decompose_stl()]
#' - [decompose_twitter()]
#' - [decompose_multiplicative()]
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
#' # twitter + median_spans
#' tidyverse_cran_downloads %>%
#'     time_decompose(count,
#'                    method       = "twitter",
#'                    frequency    = "1 week",
#'                    median_spans = "3 months",
#'                    merge        = TRUE,
#'                    message      = FALSE)
#'
#' @export
time_decompose <- function(data, target, method = c("stl", "twitter", "multiplicative"),
                           frequency = "auto", ..., merge = FALSE, message = TRUE) {
    UseMethod("time_decompose", data)
}

#' @export
time_decompose.default <- function(data, target, method = c("stl", "twitter", "multiplicative"),
                                   frequency = "auto", ..., merge = FALSE, message = TRUE) {
    stop("Object is not of class `tbl_df` or `tbl_time`.", call. = FALSE)
}

#' @export
time_decompose.tbl_time <- function(data, target, method = c("stl", "twitter", "multiplicative"),
                                    frequency = "auto", ..., merge = FALSE, message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in time_decompose(): argument "target" is missing, with no default', call. = FALSE)

    # Setup
    target_expr <- dplyr::enquo(target)
    method      <- tolower(method[[1]])

    # Set method
    if (method == "twitter") {
        decomp_tbl <- data %>%
            decompose_twitter(!! target_expr, frequency = frequency, message = message, ...)
    } else if (method == "stl") {
        decomp_tbl <- data %>%
            decompose_stl(!! target_expr, frequency = frequency, message = message, ...)
    } else if (method == "multiplicative") {
        decomp_tbl <- data %>%
            decompose_multiplicative(!! target_expr, frequency = frequency, message = message, ...)
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
time_decompose.tbl_df <- function(data, target, method = c("stl", "twitter", "multiplicative"),
                                  frequency = "auto", ..., merge = FALSE, message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in time_decompose(): argument "target" is missing, with no default', call. = FALSE)

    # Prep
    data <- prep_tbl_time(data, message = message)

    # Send to time_decompose.tbl_time
    time_decompose(data      = data,
                   target    = !! dplyr::enquo(target),
                   method    = method[[1]],
                   frequency = frequency,
                   ...       = ...,
                   merge     = merge,
                   message   = message)

}




#' @export
time_decompose.grouped_tbl_time <- function(data, target, method = c("stl", "twitter", "multiplicative"),
                                            frequency = "auto", merge = FALSE, message = FALSE, ...) {

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
            merge     = merge,
            message   = message,
            ...)

    return(ret)

}

#' @export
time_decompose.grouped_df <- function(data, target, method = c("stl", "twitter", "multiplicative"),
                                      frequency = "auto", merge = FALSE, message = FALSE, ...) {

    data <- prep_tbl_time(data, message = message)

    # Send to grouped_tbl_time
    time_decompose(data      = data,
                   target    = !! dplyr::enquo(target),
                   method    = method[[1]],
                   frequency = frequency,
                   ...       = ...,
                   merge     = merge,
                   message   = message)

}


