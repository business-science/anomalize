# single tbl_df

    Code
      stl_tbl_time <- tidyverse_cran_downloads %>% dplyr::filter(package ==
        "lubridate") %>% dplyr::ungroup() %>% dplyr::as_tibble() %>% time_decompose(
        count, method = "stl", frequency = "auto", trend = "auto")
    Message
      Converting from tbl_df to tbl_time.
      Auto-index message: index = date
      frequency = 7 days
      trend = 91 days

