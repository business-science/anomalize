# returns a ggplot

    Code
      g <- tidyverse_cran_downloads %>% dplyr::filter(package == "tidyquant") %>%
        dplyr::ungroup() %>% time_decompose(count, method = "stl") %>% anomalize(
        remainder, method = "iqr")
    Message
      frequency = 7 days
      trend = 91 days

