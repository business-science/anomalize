# time_recompose works on tbl_time

    Code
      single_recomp <- tidyverse_cran_downloads %>% dplyr::filter(package ==
        "tidyquant") %>% dplyr::ungroup() %>% time_decompose(count, method = "stl") %>%
        anomalize(remainder, method = "iqr") %>% time_recompose()
    Message
      frequency = 7 days
      trend = 91 days

