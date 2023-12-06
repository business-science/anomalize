# gesd can handle low variance data

    Code
      low_var %>% time_decompose(count, method = "stl") %>% anomalize(remainder,
        method = "gesd") %>% expect_message("Converting")
    Message
      frequency = 7 days
      trend = 91 days
      Registered S3 method overwritten by 'quantmod':
        method            from
        as.zoo.data.frame zoo 
    Code
      low_var %>% time_decompose(count, method = "twitter") %>% anomalize(remainder,
        method = "gesd") %>% expect_message("Converting")
    Message
      frequency = 7 days
      median_span = 2090 days

