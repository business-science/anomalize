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
#' @param median_spans Applies to the "twitter" method only.
#' The median spans are used to remove the trend and center the remainder.
decompose_twitter <- function(data, target, frequency = "auto", median_spans = "auto", message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in decompose_twitter(): argument "target" is missing, with no default', call. = FALSE)


    data <- prep_tbl_time(data)
    date_col_vals <- tibbletime::get_index_col(data)

    target_expr <- dplyr::enquo(target)

    date_col_name <- timetk::tk_get_timeseries_variables(data)[[1]]
    date_col_expr <- rlang::sym(date_col_name)

    # Time Series Decomposition
    decomp_tbl <- data %>%
        dplyr::pull(!! target_expr) %>%
        stats::ts(frequency = time_frequency(data, period = frequency, message = message)) %>%
        stats::stl(s.window = "periodic", robust = TRUE) %>%
        sweep::sw_tidy_decomp() %>%
        dplyr::select(-c(index, seasadj)) %>%
        # forecast::mstl() %>%
        # as.tibble() %>%
        tibble::add_column(!! date_col_name := date_col_vals, .after = 0) %>%
        purrr::set_names(c(date_col_name, "observed", "season", "trend", "remainder")) %>%
        dplyr::mutate(seasadj = observed - season) %>%
        dplyr::select(!! date_col_expr, observed, season, seasadj, trend, remainder) %>%

        # Median Groups
        time_median(observed, period = median_spans, message = message) %>%

        # Observed transformations
        dplyr::mutate(
            remainder = observed - season - median_spans
        ) %>%
        dplyr::select(!! date_col_expr, observed, season, median_spans, remainder)

    decomp_tbl <- anomalize::prep_tbl_time(decomp_tbl)

    return(decomp_tbl)

}



# 2B. STL ----

#' @export
#' @rdname decompose_methods
decompose_stl <- function(data, target, frequency = "auto", message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in decompose_stl(): argument "target" is missing, with no default', call. = FALSE)


    data <- prep_tbl_time(data)
    date_col_vals <- tibbletime::get_index_col(data)

    target_expr <- dplyr::enquo(target)

    date_col_name <- timetk::tk_get_timeseries_variables(data)[[1]]
    date_col_expr <- rlang::sym(date_col_name)

    # Time Series Decomposition
    decomp_tbl <- data %>%
        dplyr::pull(!! target_expr) %>%
        stats::ts(frequency = time_frequency(data, period = frequency, message = message)) %>%
        stats::stl(s.window = "periodic", robust = TRUE) %>%
        sweep::sw_tidy_decomp() %>%
        # forecast::mstl() %>%
        # as.tibble() %>%
        tibble::add_column(!! date_col_name := date_col_vals, .after = 0) %>%
        dplyr::select(!! date_col_expr, observed, season, trend, remainder)

    decomp_tbl <- anomalize::prep_tbl_time(decomp_tbl)

    return(decomp_tbl)

}




# 2C. Multiplicative ----

#' @export
#' @rdname decompose_methods
decompose_multiplicative <- function(data, target, frequency = "auto", message = TRUE) {

    # Checks
    if (missing(target)) stop('Error in decompose_multiplicative(): argument "target" is missing, with no default', call. = FALSE)

    # Setup inputs
    data <- prep_tbl_time(data)
    date_col_vals <- tibbletime::get_index_col(data)

    target_expr <- dplyr::enquo(target)

    date_col_name <- timetk::tk_get_timeseries_variables(data)[[1]]
    date_col_expr <- rlang::sym(date_col_name)

    frequency <- anomalize::time_frequency(data, period = frequency, message = message)

    # Time Series Decomposition
    decomp_tbl <- data %>%
        dplyr::pull(!! target_expr) %>%
        stats::ts(frequency = frequency) %>%
        stats::decompose(type = "multiplicative") %>%
        sweep::sw_tidy_decomp() %>%
        dplyr::select(-index) %>%
        dplyr::rename(remainder = random) %>%
        dplyr::select(observed, season, seasadj, trend, remainder) %>%
        tibble::add_column(!! date_col_name := date_col_vals, .after = 0)  %>%
        # Fix trend and remainder
        dplyr::mutate(
            trend = stats::supsmu(seq_along(observed), seasadj)$y,
            remainder = observed / (trend * season)
        )

    decomp_tbl <- anomalize::prep_tbl_time(decomp_tbl)

    return(decomp_tbl)

}
