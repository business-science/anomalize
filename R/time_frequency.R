#' Generate a time series frequency from a periodicity
#'
#' @param data A `tibble` with a date or datetime index.
#' @param period Either "auto", a time-based definition (e.g. "14 days"),
#' or a numeric number of observations per frequency (e.g. 10).
#' See [tibbletime::collapse_by()] for period notation.
#' @param message A boolean. If `message = TRUE`, the frequency used is output
#' along with the units in the scale of the data.
#'
#' @return Returns a scalar numeric value indicating the number of observations in the frequency or trend span.
#'
#' @details
#' A frequency is loosely defined as the number of observations that comprise a cycle
#' in a data set. The trend is loosely defined as time span that can
#' be aggregated across to visualize the central tendency of the data.
#' It's often easiest to think of frequency and trend in terms of the time-based units
#' that the data is already in. __This is what `time_frequency()` and `time_trend()`
#' enable: using time-based periods to define the frequency or trend.__
#'
#' __Frequency__:
#'
#' As an example, a weekly cycle is often 5-days (for working
#' days) or 7-days (for calendar days). Rather than specify a frequency of 5 or 7,
#' the user can specify `period = "1 week"`, and
#' time_frequency()` will detect the scale of the time series and return 5 or 7
#' based on the actual data.
#'
#' The `period` argument has three basic options for returning a frequency.
#' Options include:
#' - `"auto"`: A target frequency is determined using a pre-defined template (see `template` below).
#' - `time-based duration`: (e.g. "1 week" or "2 quarters" per cycle)
#' - `numeric number of observations`: (e.g. 5 for 5 observations per cycle)
#'
#' The `template` argument is only used when `period = "auto"`. The template is a tibble
#' of three features: `time_scale`, `frequency`, and `trend`. The algorithm will inspect
#' the scale of the time series and select the best frequency that matches the scale and
#' number of observations per target frequency. A frequency is then chosen on be the
#' best match. The predefined template is stored in a function `time_scale_template()`.
#' However, the user can come up with his or her own template changing the values
#' for frequency in the data frame and saving it to `anomalize_options$time_scale_template`.
#'
#' __Trend__:
#'
#' As an example, the trend of daily data is often best aggregated by evaluating
#' the moving average over a quarter or a month span. Rather than specify the number
#' of days in a quarter or month, the user can specify "1 quarter" or "1 month",
#' and the `time_trend()` function will return the correct number of observations
#' per trend cycle. In addition, there is an option, `period = "auto"`, to
#' auto-detect an appropriate trend span depending on the data. The `template`
#' is used to define the appropriate trend span.
#'
#' @examples
#'
#' library(dplyr)
#'
#' data(tidyverse_cran_downloads)
#'
#' #### FREQUENCY DETECTION ####
#'
#' # period = "auto"
#' tidyverse_cran_downloads %>%
#'     filter(package == "tidyquant") %>%
#'     ungroup() %>%
#'     time_frequency(period = "auto")
#'
#' time_scale_template()
#'
#' # period = "1 month"
#' tidyverse_cran_downloads %>%
#'     filter(package == "tidyquant") %>%
#'     ungroup() %>%
#'     time_frequency(period = "1 month")
#'
#' #### TREND DETECTION ####
#'
#' tidyverse_cran_downloads %>%
#'     filter(package == "tidyquant") %>%
#'     ungroup() %>%
#'     time_trend(period = "auto")


#' @export
#' @rdname time_frequency
time_frequency <- function(data, period = "auto", message = TRUE) {

    # Checks
    if (!is.data.frame(data)) stop("Error time_frequency(): Object must inherit class `data.frame`, `tbl_df` or `tbl_time`.")

    if (dplyr::is.grouped_df(data))
        stop(glue::glue("Error time_frequency(): Cannot use on a grouped data frame.
                        Frequency should be performed on a single time series."))

    # Setup inputs
    template <- get_time_scale_template()
    data <- prep_tbl_time(data, message = F)

    index_expr <- data %>% tibbletime::get_index_quo()
    index_name <- dplyr::quo_name(index_expr)

    # Get timeseries summary attributes
    ts_summary <- data %>%
        tibbletime::get_index_col() %>%
        timetk::tk_get_timeseries_summary()

    ts_nobs  <- ts_summary$n.obs
    ts_scale <- ts_summary$scale


    if (is.numeric(period)) {
        # 1. Numeric Periods
        freq <- period

    } else if (period != "auto") {
        # 2. Text (e.g. period = "14 days")
        freq <- data %>%
            tibbletime::collapse_by(period = period) %>%
            dplyr::count(!! index_expr) %>%
            dplyr::pull(n) %>%
            stats::median(na.rm = T)

    } else {
        # 3. period = "auto"

        periodicity_target <- template %>%
            target_time_decomposition_scale(time_scale = ts_scale, target = "frequency", index_shift = 0)

        freq <- data %>%
            tibbletime::collapse_by(period = periodicity_target) %>%
            dplyr::count(!! index_expr) %>%
            dplyr::pull(n) %>%
            stats::median(na.rm = T)

        # Insufficient observations: nobs-to-freq should be at least 3-1
        if (ts_nobs < 3*freq) {
            periodicity_target <- template %>%
                target_time_decomposition_scale(time_scale = ts_scale, target = "frequency", index_shift = 1)

            freq <- data %>%
                tibbletime::collapse_by(period = periodicity_target) %>%
                dplyr::count(!! index_expr) %>%
                dplyr::pull(n) %>%
                stats::median(na.rm = T)
        }

        if (ts_nobs < 3*freq) {
            freq <- 1
        }
    }

    if (message) {
        freq_string <- glue::glue("frequency = {freq} {ts_scale}s")
        message(freq_string)
    }

    return(freq)
}

#' @export
#' @rdname time_frequency
time_trend <- function(data, period = "auto", message = TRUE) {

    # Checks
    if (!is.data.frame(data)) stop("Error time_trend(): Object must inherit class `data.frame`, `tbl_df` or `tbl_time`.")

    if (dplyr::is.grouped_df(data))
        stop(glue::glue("Cannot use on a grouped data frame.
                        Frequency should be performed on a single time series."))

    # Setup inputs
    template <- get_time_scale_template()
    data <- prep_tbl_time(data, message = F)

    index_expr <- data %>% tibbletime::get_index_quo()
    index_name <- dplyr::quo_name(index_expr)

    # Get timeseries summary attributes
    ts_summary <- data %>%
        tibbletime::get_index_col() %>%
        timetk::tk_get_timeseries_summary()

    ts_nobs  <- ts_summary$n.obs
    ts_scale <- ts_summary$scale


    if (is.numeric(period)) {
        # 1. Numeric Periods
        trend <- period

    } else if (period != "auto") {
        # 2. Text (e.g. period = "14 days")
        trend <- data %>%
            tibbletime::collapse_by(period = period) %>%
            dplyr::count(!! index_expr) %>%
            dplyr::pull(n) %>%
            stats::median(na.rm = T)

    } else {
        # 3. period = "auto"

        periodicity_target <- template %>%
            target_time_decomposition_scale(time_scale = ts_scale, target = "trend", index_shift = 0)

        trend <- data %>%
            tibbletime::collapse_by(period = periodicity_target) %>%
            dplyr::count(!! index_expr) %>%
            dplyr::pull(n) %>%
            stats::median(na.rm = T)

        # Insufficient observations: nobs-to-trend should be at least 2-1
        if (ts_nobs / trend < 2) {
            periodicity_target <- template %>%
                target_time_decomposition_scale(time_scale = ts_scale, target = "trend", index_shift = 1)

            trend <- data %>%
                tibbletime::collapse_by(period = periodicity_target) %>%
                dplyr::count(!! index_expr) %>%
                dplyr::pull(n) %>%
                stats::median(na.rm = T)

            trend <- ceiling(trend)

        }

        if (ts_nobs / trend < 2) {
            trend <- ts_nobs
        }
    }

    if (message) {
        trend_string <- glue::glue("trend = {trend} {ts_scale}s")
        message(trend_string)
    }

    return(trend)
}

# Helper function to get the time decomposition scale
target_time_decomposition_scale <- function(template, time_scale, target = c("frequency", "trend"), index_shift = 0) {

    target_expr <-  rlang::sym(target[[1]])

    idx <- which(template$time_scale == time_scale) - index_shift
    key_value <- template$time_scale[idx]

    template %>%
        dplyr::filter(time_scale == key_value) %>%
        dplyr::pull(!! target_expr)
}
