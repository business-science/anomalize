# gesd can handle low variance data

    Code
      low_var %>% time_decompose(count, method = "twitter") %>% anomalize(remainder,
        method = "gesd") %>% expect_message("Converting")
    Message
      frequency = 7 days
      median_span = 2090 days

