#' anomalize: Tidy anomaly detection
#'
#' @details
#' The 'anomalize' package enables a "tidy" workflow for detecting anomalies in data.
#' The main functions are time_decompose(), anomalize(), and time_recompose().
#' When combined, it's quite simple to decompose time series, detect anomalies,
#' and create bands separating the "normal" data from the anomalous data at scale (i.e. for multiple time series).
#' Time series decomposition is used to remove trend and seasonal components via the time_decompose() function
#' and methods include seasonal decomposition of time series by Loess and
#' seasonal decomposition by piecewise medians. The anomalize() function implements
#' two methods for anomaly detection of residuals including using an inner quartile range
#' and generalized extreme studentized deviation. These methods are based on
#' those used in the `forecast` package and the Twitter `AnomalyDetection` package.
#' Refer to the associated functions for specific references for these methods.
#'
#' To learn more about `anomalize`, start with the vignettes:
#'  `browseVignettes(package = "anomalize")`
#'
#'
#' @docType package
#' @name anomalize_package
#'
#' @importFrom rlang := !! !!!
#' @importFrom dplyr %>% n row_number contains quo_name
#' @importFrom stats median mad qt as.formula
#' @import ggplot2

NULL
