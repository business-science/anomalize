#' Get and modify time scale template
#'
#' @param data A `tibble` with a "time_scale", "frequency", and "trend" columns.
#'
#'
#' @details
#'
#' Used to get and set the time scale template, which is used by `time_frequency()`
#' and `time_trend()` when `period = "auto"`.
#'
#' @seealso [time_frequency()], [time_trend()]
#'
#' @examples
#'
#' get_time_scale_template()
#'
#' set_time_scale_template(time_scale_template())
#'



#' @export
#' @rdname time_scale_template
set_time_scale_template <- function(data) {
    if (!missing(data)) {
        options(time_scale_template = data)
    }
    #getOption('time_scale_template')
}

#' @export
#' @rdname time_scale_template
get_time_scale_template <- function() {
    getOption('time_scale_template')
}

#' @export
#' @rdname time_scale_template
time_scale_template <- function() {

    tibble::tribble(
        ~ "time_scale",   ~ "frequency",        ~ "trend",
        "second",         "1 hour",             "12 hours",
        "minute",         "1 day",              "14 days",
        "hour",           "1 day",              "1 month",
        "day",            "1 week",             "3 months",
        "week",           "1 quarter",          "1 year",
        "month",          "1 year",             "5 years",
        "quarter",        "1 year",             "10 years",
        "year",           "5 years",            "30 years"
    )

}





