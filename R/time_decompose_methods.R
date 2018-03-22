#' Methods that power time_decompose()
#'
#' @inheritParams time_decompose
#'
#' @return A `tbl_time` object containing the time series decomposition.
#'
#' @seealso [time_decompose()]
#'
#' @examples
#'
#' library(dplyr)
#'
#' tidyverse_cran_downloads %>%
#'     ungroup() %>%
#'     filter(package == "tidyquant") %>%
#'     decompose_stl(count)
#'
#'
#' @references
#' - The "twitter" method is used in Twitter's [`AnomalyDetection` package](https://github.com/twitter/AnomalyDetection)
#'
#' @name decompose_methods

# 2A. Twitter ----

#' @export
#' @rdname decompose_methods
decompose_twitter <- function(data, target, frequency = "auto", trend = "auto", message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in decompose_twitter(): argument "target" is missing, with no default', call. = FALSE)
    # if (!is.null(median_spans))
    #     if (!is.numeric(median_spans)) stop('Error in decompse_twitter(): argument "median_spans" must be numeric.', call. = FALSE)

    data <- prep_tbl_time(data)
    date_col_vals <- tibbletime::get_index_col(data)

    target_expr <- dplyr::enquo(target)

    date_col_name <- timetk::tk_get_timeseries_variables(data)[[1]]
    date_col_expr <- rlang::sym(date_col_name)

    freq <- time_frequency(data, period = frequency, message = message)
    # trnd <- time_trend(data, period = trend)

    # Time Series Decomposition
    decomp_tbl <- data %>%
        dplyr::pull(!! target_expr) %>%
        stats::ts(frequency = freq) %>%
        stats::stl(s.window = "periodic", robust = TRUE) %>%
        sweep::sw_tidy_decomp() %>%
        dplyr::select(-c(index, seasadj)) %>%
        # forecast::mstl() %>%
        # as.tibble() %>%
        tibble::add_column(!! date_col_name := date_col_vals, .after = 0) %>%
        purrr::set_names(c(date_col_name, "observed", "season", "trend", "remainder")) %>%
        dplyr::mutate(seasadj = observed - season) %>%
        dplyr::select(!! date_col_expr, observed, season, seasadj, trend, remainder)

    # Median Span Logic
    trnd <- time_trend(data, period = trend, message = FALSE)
    median_spans_needed <- round(nrow(data) / trnd)

    decomp_tbl <- decomp_tbl %>%
        dplyr::mutate(
            .period_groups = rep(1:median_spans_needed, length.out = nrow(.)) %>% sort()
        ) %>%
        dplyr::group_by(.period_groups) %>%
        dplyr::mutate(median_spans = median(observed, na.rm = T)) %>%
        dplyr::ungroup() %>%
        dplyr::select(-.period_groups)

    if (message) {
        med_span <- decomp_tbl %>%
            dplyr::count(median_spans) %>%
            dplyr::pull(n) %>%
            median(na.rm = TRUE)

        med_scale <- decomp_tbl %>%
            timetk::tk_index() %>%
            timetk::tk_get_timeseries_summary() %>%
            dplyr::pull(scale)

        message(glue::glue("median_span = {med_span} {med_scale}s"))
    }

    # Remainder calculation
    decomp_tbl <- decomp_tbl %>%
        dplyr::mutate(
            remainder = observed - season - median_spans
        ) %>%
        dplyr::select(!! date_col_expr, observed, season, median_spans, remainder)

    decomp_tbl <- anomalize::prep_tbl_time(decomp_tbl)

    return(decomp_tbl)

}

# NOT USED
# Helper function for decompose_twitter
# time_median <- function(data, target, period = "auto", template = time_scale_template(), message = TRUE) {
#
#     # Setup inputs
#     data <- prep_tbl_time(data, message = F)
#
#     date_col_expr <- tibbletime::get_index_quo(data)
#     date_col_name <- dplyr::quo_name(date_col_expr)
#
#     target_expr   <- dplyr::enquo(target)
#
#     # For median_span (trend) = "auto" use template
#     if (period == "auto") {
#
#         # Get timeseries summary attributes
#         ts_summary <- data %>%
#             tibbletime::get_index_col() %>%
#             timetk::tk_get_timeseries_summary()
#
#         ts_scale <- ts_summary$scale
#
#         period <- template %>%
#             target_time_decomposition_scale(ts_scale, "trend", index_shift = 0)
#
#     }
#
#     # Use time_apply()
#     ret <- data %>%
#         time_apply(!! target_expr, period = period,
#                    .fun = median, na.rm = T, clean = F, message = message) %>%
#         dplyr::rename(median_spans = time_apply)
#
#     if (message) message(glue::glue("median_span = {period}"))
#
#     return(ret)
#
# }


# 2B. STL ----

#' @export
#' @rdname decompose_methods
decompose_stl <- function(data, target, frequency = "auto", trend = "auto", message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in decompose_stl(): argument "target" is missing, with no default', call. = FALSE)


    data <- prep_tbl_time(data)
    date_col_vals <- tibbletime::get_index_col(data)

    target_expr <- dplyr::enquo(target)

    date_col_name <- timetk::tk_get_timeseries_variables(data)[[1]]
    date_col_expr <- rlang::sym(date_col_name)

    freq <- time_frequency(data, period = frequency, message = message)
    trnd <- time_trend(data, period = trend, message = message)

    # Time Series Decomposition
    decomp_tbl <- data %>%
        dplyr::pull(!! target_expr) %>%
        stats::ts(frequency = freq) %>%
        stats::stl(s.window = "periodic", t.window = trnd, robust = TRUE) %>%
        sweep::sw_tidy_decomp() %>%
        # forecast::mstl() %>%
        # as.tibble() %>%
        tibble::add_column(!! date_col_name := date_col_vals, .after = 0) %>%
        dplyr::select(!! date_col_expr, observed, season, trend, remainder)

    decomp_tbl <- anomalize::prep_tbl_time(decomp_tbl)

    return(decomp_tbl)

}



# NOT USED: USE TRANSFORMATIONS INSTEAD
# # 2C. Multiplicative
#
# #' @export
# #' @rdname decompose_methods
# decompose_multiplicative <- function(data, target, frequency = "auto", trend = "auto", message = TRUE) {
#
#     # Checks
#     if (missing(target)) stop('Error in decompose_multiplicative(): argument "target" is missing, with no default', call. = FALSE)
#
#     # Setup inputs
#     data <- prep_tbl_time(data)
#     date_col_vals <- tibbletime::get_index_col(data)
#
#     target_expr <- dplyr::enquo(target)
#
#     date_col_name <- timetk::tk_get_timeseries_variables(data)[[1]]
#     date_col_expr <- rlang::sym(date_col_name)
#
#     frequency <- anomalize::time_frequency(data, period = frequency, message = message)
#     # Note that trend is unused in super smoother (`supsmu()`)
#
#     # Time Series Decomposition
#     decomp_tbl <- data %>%
#         dplyr::pull(!! target_expr) %>%
#         stats::ts(frequency = frequency) %>%
#         stats::decompose(type = "multiplicative") %>%
#         sweep::sw_tidy_decomp() %>%
#         dplyr::select(-index) %>%
#         dplyr::rename(remainder = random) %>%
#         dplyr::select(observed, season, seasadj, trend, remainder) %>%
#         tibble::add_column(!! date_col_name := date_col_vals, .after = 0)  %>%
#         # Fix trend and remainder
#         dplyr::mutate(
#             trend = stats::supsmu(seq_along(observed), seasadj)$y,
#             remainder = observed / (trend * season)
#         ) %>%
#         dplyr::select(-seasadj)
#
#     decomp_tbl <- anomalize::prep_tbl_time(decomp_tbl)
#
#     return(decomp_tbl)
#
# }
