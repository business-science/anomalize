#' anomalize: Tidy anomaly detection
#'
#' @details
#' The `anomalize` package enables a tidy workflow for detecting anomalies in data.
#' The main functions are `time_decompose()`, `anomalize()`, and `time_recompose()`.
#' When combined, it's quite simple to decompose time series, detect anomalies,
#' and create bands separating the "normal" data from the anomalous data.
#'
#' To learn more about `anomalize`, start with the vignettes:
#'  `browseVignettes(package = "anomalize")`
#'
#' @docType package
#' @name anomalize_package
#'
#' @importFrom rlang := !! !!!
#' @importFrom dplyr %>% n row_number contains quo_name
#' @importFrom stats median mad qt as.formula
#' @import ggplot2

NULL
