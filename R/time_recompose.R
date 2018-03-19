#' Recompose bands separating anomalies from "normal" observations
#'
#' @param data A `tibble` or `tbl_time` object that has been
#' processed with `time_decompose()` and `anomalize()`.
#'
#' @return Returns a `tbl_time` object.
#'
#' @details
#' The `time_recompose()` function is used to generate bands around the
#' "normal" levels of observed values. The function uses the remainder_l1
#' and remainder_l2 levels produced during the [anomalize()] step
#' and the season and trend/median_spans values from the [time_decompose()]
#' step to reconstruct bands around the normal values.
#'
#' The following key names are required: observed:remainder from the
#' `time_decompose()` step and remainder_l1 and remainder_l2 from the
#' `anomalize()` step.
#'
#'
#' @seealso
#' Time Series Anomaly Detection Functions (anomaly detection workflow):
#' - [time_decompose()]
#' - [anomalize()]
#'
#' @examples
#'
#' library(dplyr)
#'
#' data(tidyverse_cran_downloads)
#'
#' # Basic Usage
#' tidyverse_cran_downloads %>%
#'     time_decompose(count, method = "stl") %>%
#'     anomalize(remainder, method = "iqr") %>%
#'     time_recompose()
#'
#'
#' @export
time_recompose <- function(data) {
    UseMethod("time_recompose", data)
}

#' @export
time_recompose.default <- function(data) {
    stop("Error time_recompose(): Object is not of class `tbl_df` or `tbl_time`.", call. = FALSE)
}

#' @export
time_recompose.tbl_time <- function(data) {

    # Checks
    column_names <- names(data)
    check_names <- c("observed", "remainder", "remainder_l1", "remainder_l2") %in% column_names
    if (!all(check_names)) stop('Error in time_recompose(): key names are missing. Make sure observed:remainder, remainder_l1, and remainder_l2 are present', call. = FALSE)

    # Setup
    # target_expr <- dplyr::enquo(target)
    # method      <- tolower(method[[1]])

    l1 <- data %>%
        dplyr::select(observed:remainder, contains("_l1")) %>%
        dplyr::select(-c(observed, remainder)) %>%
        apply(MARGIN = 1, FUN = sum)

    l2 <- data %>%
        dplyr::select(observed:remainder, contains("_l2")) %>%
        dplyr::select(-c(observed, remainder)) %>%
        apply(MARGIN = 1, FUN = sum)

    ret <- data %>%
        # add_column(!! paste0(quo_name(target_expr), "_l1") := l1)
        tibble::add_column(
            recomposed_l1 = l1,
            recomposed_l2 = l2
        )

    return(ret)

}

#' @export
time_recompose.tbl_df <- function(data) {

    # Prep
    data <- prep_tbl_time(data, message = FALSE)

    # Send to time_recompose.tbl_time
    time_recompose(data      = data)

}


#' @export
time_recompose.grouped_tbl_time <- function(data) {

    # Checks
    column_names <- names(data)
    check_names <- c("observed", "remainder", "remainder_l1", "remainder_l2") %in% column_names
    if (!all(check_names)) stop('Error in time_recompose(): key names are missing. Make sure observed:remainder, remainder_l1, and remainder_l2 are present', call. = FALSE)

    # Setup
    group_names     <- dplyr::groups(data)
    group_vars_expr <- rlang::syms(group_names)

    # Recompose l1 and l2 bands
    l1 <- data %>%
        dplyr::ungroup() %>%
        dplyr::select(observed:remainder, contains("_l1")) %>%
        dplyr::select(-c(observed, remainder)) %>%
        apply(MARGIN = 1, FUN = sum)

    l2 <- data %>%
        dplyr::ungroup() %>%
        dplyr::select(observed:remainder, contains("_l2")) %>%
        dplyr::select(-c(observed, remainder)) %>%
        apply(MARGIN = 1, FUN = sum)

    ret <- data %>%
        dplyr::ungroup() %>%
        tibble::add_column(
            recomposed_l1 = l1,
            recomposed_l2 = l2
        ) %>%
        dplyr::group_by(!!! group_vars_expr)

    return(ret)

}

#' @export
time_recompose.grouped_df <- function(data) {

    data <- prep_tbl_time(data, message = message)

    # Send to grouped_tbl_time
    time_recompose(data      = data)

}




