#' Automatically create tibbletime objects from tibbles
#'
#' @param data A `tibble`.
#' @param message A boolean. If `TRUE`, returns a message indicating any
#' conversion details important to know during the conversion to `tbl_time` class.
#'
#' @return Returns a `tibbletime` object of class `tbl_time`.
#'
#' @details
#' Detects a date or datetime index column and automatically
#'
#' @seealso [tibbletime::as_tbl_time()]
#'
#' @examples
#'
#' library(dplyr)
#' library(tibbletime)
#'
#' data_tbl <- tibble(
#'     date  = seq.Date(from = as.Date("2018-01-01"), by = "day", length.out = 10),
#'     value = rnorm(10)
#'     )
#'
#' prep_tbl_time(data_tbl)
#'
#' @export
prep_tbl_time <- function(data, message = FALSE) {
    UseMethod("prep_tbl_time", data)
}


prep_tbl_time.default <- function(data, message = FALSE) {
    stop("Object is not of class `data.frame`.", call. = FALSE)
}


#' @export
prep_tbl_time.data.frame <- function(data, message = FALSE) {

    cl  <- class(data)[[1]]
    idx <- timetk::tk_get_timeseries_variables(data)[[1]]

    data <- data %>%
        tibbletime::as_tbl_time(index = !! rlang::sym(idx))

    if (message) message(glue::glue("Converting from {cl} to {class(data)[[1]]}.
                                    Auto-index message: index = {idx}"))

    return(data)
}

#' @export
prep_tbl_time.tbl_time <- function(data, message = FALSE) {
    return(data)
}
