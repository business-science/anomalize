#' Clean anomalies from anomalized data
#'
#' @param data A `tibble` or `tbl_time` object.
#'
#' @return Returns a `tibble` / `tbl_time` object with a new column "observed_cleaned".
#'
#' @details
#' The `clean_anomalies()` function is used to replace outliers with the seasonal and trend component.
#' This is often desirable when forecasting with noisy time series data to improve trend detection.
#'
#' To clean anomalies, the input data must be detrended with `time_decompose()` and anomalized with `anomalize()`.
#' The data can also be recomposed with `time_recompose()`.
#'
#' @seealso
#' Time Series Anomaly Detection Functions (anomaly detection workflow):
#' - [time_decompose()]
#' - [anomalize()]
#' - [time_recompose()]
#'
#' @examples
#'
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
#'     anomalize(remainder, method = "iqr") %>%
#'     clean_anomalies()
#' }
#'
#' @export
clean_anomalies <- function(data) {
    UseMethod("clean_anomalies", data)
}

#' @export
clean_anomalies.default <- function(data) {
    stop("Error clean_anomalies(): Object is not of class `tbl_df` or `tbl_time`.", call. = FALSE)
}

#' @export
clean_anomalies.tbl_df <- function(data) {

    # Checks
    check_clean_anomalies_input(data)

    # Get method col
    method_col <- get_method_col(data)

    if (method_col == "trend") {
        data %>%
            dplyr::mutate(observed_cleaned = ifelse(anomaly == "Yes", season + trend, observed))
    } else {
        data %>%
            dplyr::mutate(observed_cleaned = ifelse(anomaly == "Yes", season + median_spans, observed))
    }

}

check_clean_anomalies_input <- function(data) {

    data_names <- names(data)

    # Detect method - STL or Twitter
    method_names <- c("trend", "median_spans")
    method_name_in_data <- any(method_names %in% data_names)

    # Check - No method name in data
    if (!method_name_in_data) stop("Error clean_anomalies(): Output does not contain a column named trend or median_spans. This may occur if the output was not detrended with time_decompose().", call. = FALSE)

    # Check - Required names from time_decompose()
    required_names <- c("observed", "season")
    required_names_in_data <- all(required_names %in% data_names)
    if (!required_names_in_data) stop("Error clean_anomalies(): Output does not contain columns named observed and season. This may occur if the output was not detrended with time_decompose().", call. = FALSE)

    # Check - Required names from time_decompose()
    required_names <- c("anomaly")
    required_names_in_data <- all(required_names %in% data_names)
    if (!required_names_in_data) stop("Error clean_anomalies(): Output does not contain columns named anomaly. This may occur if the output was not anomalized with anomalize().", call. = FALSE)


}


get_method_col <- function(data) {

    data_names <- names(data)

    # Detect method - STL or Twitter
    method_names <- c("trend", "median_spans")
    method_name_in_data <- method_names %in% data_names

    method_names[method_name_in_data]

}


