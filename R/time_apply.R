#' Apply a function to a time series by period
#'
#' @inheritParams tibbletime::collapse_by
#' @param data A `tibble` with a date or datetime index.
#' @param target A column to apply the function to
#' @param period A time-based definition (e.g. "2 weeks").
#' or a numeric number of observations per frequency (e.g. 10).
#' See [tibbletime::collapse_by()] for period notation.
#' @param .fun A function to apply (e.g. `median`)
#' @param ... Additional parameters passed to the function, `.fun`
#' @param message A boolean. If `message = TRUE`, the frequency used is output
#' along with the units in the scale of the data.
#'
#' @return Returns a `tibbletime` object of class `tbl_time`.
#'
#' @details
#' Uses a time-based period to apply functions to. This is useful in circumstances where you want to
#' compare the observation values to aggregated values such as `mean()` or `median()`
#' during a set time-based period. The returned output extends the
#' length of the data frame so the differences can easily be computed.
#'
#'
#' @examples
#'
#' library(dplyr)
#'
#' data(tidyverse_cran_downloads)
#'
#' # Basic Usage
#' tidyverse_cran_downloads %>%
#'     time_apply(count, period = "1 week", .fun = mean, na.rm = TRUE)
#'
#' @export
time_apply <- function(data, target, period, .fun, ...,
                       start_date = NULL, side = "end", clean = FALSE, message = TRUE) {

    UseMethod("time_apply", data)

}

#' @export
time_apply.default <- function(data, target, period, .fun, ...,
                               start_date = NULL, side = "end", clean = FALSE, message = TRUE) {
    stop("Object is not of class `tbl_df` or `tbl_time`.", call. = FALSE)
}


#' @export
time_apply.data.frame <- function(data, target, period, .fun, ...,
                                  start_date = NULL, side = "end", clean = FALSE, message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in time_apply(): argument "target" is missing, with no default', call. = FALSE)
    if (missing(period)) stop('Error in time_apply(): argument "period" is missing, with no default', call. = FALSE)
    if (missing(.fun)) stop('Error in time_apply(): argument ".fun" is missing, with no default', call. = FALSE)


    # Setup inputs
    data <- prep_tbl_time(data, message = F)

    date_col_expr <- tibbletime::get_index_quo(data)
    date_col_name <- dplyr::quo_name(date_col_expr)

    target_expr   <- dplyr::enquo(target)

    # Function apply logic
    if (is.character(period)) {
        # See collapse_by for valid character sequences (e.g. "1 Y")
        ret <- data %>%
            tibbletime::collapse_by(period = period, clean = clean, start_date = start_date, side = side) %>%
            dplyr::group_by(!! tibbletime::get_index_quo(.)) %>%
            dplyr::mutate(time_apply = .fun(!! target_expr, ...)) %>%
            dplyr::ungroup() %>%
            dplyr::mutate(!! date_col_name := data %>% dplyr::pull(!! date_col_expr))

    } else {
        # Numeric (e.g. every 15 data points)
        ret <- data %>%
            dplyr::mutate(
                .period_groups = c(0, (1:(nrow(.) - 1) %/% period))
            ) %>%
            dplyr::group_by(.period_groups) %>%
            dplyr::mutate(
                time_apply = .fun(!! target_expr, ...)
            ) %>%
            dplyr::ungroup() %>%
            dplyr::select(-.period_groups)
    }

    return(ret)

}

#' @export
time_apply.grouped_df <- function(data, target, period, .fun, ...,
                                  start_date = NULL, side = "end", clean = FALSE, message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in time_apply(): argument "target" is missing, with no default', call. = FALSE)
    if (missing(period)) stop('Error in time_apply(): argument "period" is missing, with no default', call. = FALSE)
    if (missing(.fun)) stop('Error in time_apply(): argument ".fun" is missing, with no default', call. = FALSE)


    # Setup
    data <- prep_tbl_time(data, message = F)

    target_expr <- dplyr::enquo(target)

    # Map time_apply.data.frame
    ret <- data %>%
        grouped_mapper(
            .f         = time_apply,
            target     = !! target_expr,
            period     = period,
            .fun       = .fun,
            ...        = ...,
            start_date = start_date,
            side       = side,
            clean      = clean,
            message    = message)

    return(ret)

}

