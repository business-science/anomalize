library(dplyr)
library(tibbletime)
library(cranlogs)

pkgs <- c(
    "tidyr", "lubridate", "dplyr",
    "broom", "tidyquant", "tidytext",
    "ggplot2", "purrr", "glue",
    "stringr", "forcats", "knitr",
    "readr", "tibble", "tidyverse"
)

tidyverse_cran_downloads <- cran_downloads(pkgs, from = "2017-01-01", to = "2018-03-01") %>%
    group_by(package) %>%
    as_tbl_time(date)

tidyverse_cran_downloads
