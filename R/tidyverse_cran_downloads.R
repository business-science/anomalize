#' Downloads of various "tidyverse" packages from CRAN
#'
#' A dataset containing the daily download counts from 2017-01-01 to 2018-03-01
#' for the following tidyverse packages:
#' - `tidyr`
#' - `lubridate`
#' - `dplyr`
#' - `broom`
#' - `tidyquant`
#' - `tidytext`
#' - `ggplot2`
#' - `purrr`
#' - `stringr`
#' - `forcats`
#' - `knitr`
#' - `readr`
#' - `tibble`
#' - `tidyverse`
#'
#'
#' @format A `grouped_tbl_time` object with 6,375 rows and 3 variables:
#' \describe{
#'   \item{date}{Date of the daily observation}
#'   \item{count}{Number of downloads that day}
#'   \item{package}{The package corresponding to the daily download number}
#' }
#'
#' @source
#' The package downloads come from CRAN by way of the `cranlogs` package.
"tidyverse_cran_downloads"
