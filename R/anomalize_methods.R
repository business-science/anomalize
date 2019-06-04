#' Methods that power anomalize()
#'
#' @inheritParams anomalize
#' @param x A vector of numeric data.
#' @param verbose A boolean. If `TRUE`, will return a list containing useful information
#' about the anomalies. If `FALSE`, just returns a vector of "Yes" / "No" values.
#'
#' @return Returns character vector or list depending on the value of `verbose`.
#'
#'
#' @seealso [anomalize()]
#'
#' @examples
#'
#' set.seed(100)
#' x <- rnorm(100)
#' idx_outliers <- sample(100, size = 5)
#' x[idx_outliers] <- x[idx_outliers] + 10
#'
#' iqr(x, alpha = 0.05, max_anoms = 0.2)
#' iqr(x, alpha = 0.05, max_anoms = 0.2, verbose = TRUE)
#'
#' gesd(x, alpha = 0.05, max_anoms = 0.2)
#' gesd(x, alpha = 0.05, max_anoms = 0.2, verbose = TRUE)
#'
#'
#' @references
#' - The IQR method is used in [`forecast::tsoutliers()`](https://github.com/robjhyndman/forecast/blob/master/R/clean.R)
#' - The GESD method is used in Twitter's [`AnomalyDetection`](https://github.com/twitter/AnomalyDetection) package and is also available as a function in [@raunakms's GESD method](https://github.com/raunakms/GESD/blob/master/runGESD.R)
#'
#' @name anomalize_methods

# 1A. IQR Method ----

#' @export
#' @rdname anomalize_methods
iqr <- function(x, alpha = 0.05, max_anoms = 0.2, verbose = FALSE) {
  quantile_x <- stats::quantile(x, prob = c(0.25, 0.75), na.rm = TRUE)
  iq_range <- quantile_x[[2]] - quantile_x[[1]]
  limits <- quantile_x + (0.15 / alpha) * iq_range * c(-1, 1)

  outlier_idx <- ((x < limits[1]) | (x > limits[2]))
  outlier_vals <- x[outlier_idx]
  outlier_response <- ifelse(outlier_idx == TRUE, "Yes", "No")

  vals_tbl <- tibble::tibble(value = x) %>%
    tibble::rownames_to_column(var = "index") %>%
    # Establish limits and assess if outside of limits
    dplyr::mutate(
      limit_lower = limits[1],
      limit_upper = limits[2],
      abs_diff_lower = ifelse(value <= limit_lower, abs(value - limit_lower), 0),
      abs_diff_upper = ifelse(value >= limit_upper, abs(value - limit_upper), 0),
      max_abs_diff = ifelse(abs_diff_lower > abs_diff_upper, abs_diff_lower, abs_diff_upper)
    ) %>%
    dplyr::select(index, dplyr::everything()) %>%
    dplyr::select(-c(abs_diff_lower, abs_diff_upper)) %>%
    # Sort by absolute distance from centerline of limits
    dplyr::mutate(
      centerline = (limit_upper + limit_lower) / 2,
      sorting = abs(value - centerline)
    ) %>%
    dplyr::arrange(dplyr::desc(sorting)) %>%
    dplyr::select(-c(centerline, sorting)) %>%
    tibble::rownames_to_column(var = "rank") %>%
    dplyr::mutate(
      rank = as.numeric(rank),
      index = as.numeric(index)
    ) %>%
    # Identify outliers
    dplyr::arrange(dplyr::desc(max_abs_diff)) %>%
    dplyr::mutate(
      outlier = ifelse(max_abs_diff > 0, "Yes", "No"),
      below_max_anoms = ifelse(row_number() / n() > max_anoms,
        "No", "Yes"
      ),
      outlier_reported = ifelse(outlier == "Yes" & below_max_anoms == "Yes",
        "Yes", "No"
      ),
      direction = dplyr::case_when(
        (outlier_reported == "Yes") & (value > limit_upper) ~ "Up",
        (outlier_reported == "Yes") & (value < limit_lower) ~ "Down",
        TRUE ~ "NA"
      ),
      direction = ifelse(direction == "NA", NA, direction)
    )

  vals_tbl_filtered <- vals_tbl %>%
    dplyr::filter(below_max_anoms == "Yes") %>%
    dplyr::select(-c(max_abs_diff:below_max_anoms)) %>%
    dplyr::rename(outlier = outlier_reported)

  # Critical Limits
  if (any(vals_tbl$outlier == "No")) {
    # Non outliers identified, pick first limit
    limit_tbl <- vals_tbl %>%
      dplyr::filter(outlier == "No") %>%
      dplyr::slice(1)
    limits_vec <- c(
      limit_lower = limit_tbl$limit_lower,
      limit_upper = limit_tbl$limit_upper
    )
  } else {
    # All outliers, pick last limits
    limit_tbl <- vals_tbl %>%
      dplyr::slice(n())
    limits_vec <- c(
      limit_lower = limit_tbl$limit_lower,
      limit_upper = limit_tbl$limit_upper
    )
  }

  # Return results
  if (verbose) {
    outlier_list <- list(
      outlier = vals_tbl %>% dplyr::arrange(index) %>% dplyr::pull(outlier_reported),
      outlier_idx = vals_tbl %>% dplyr::filter(outlier_reported == "Yes") %>% dplyr::pull(index),
      outlier_vals = vals_tbl %>% dplyr::filter(outlier_reported == "Yes") %>% dplyr::pull(value),
      outlier_direction = vals_tbl %>% dplyr::filter(outlier_reported == "Yes") %>% dplyr::pull(direction),
      critical_limits = limits_vec,
      outlier_report = vals_tbl_filtered
    )
    return(outlier_list)
  } else {
    return(vals_tbl %>% dplyr::arrange(index) %>% dplyr::pull(outlier_reported))
  }
}



# 1B. GESD: Generalized Extreme Studentized Deviate Test ----

#' @export
#' @rdname anomalize_methods
gesd <- function(x, alpha = 0.05, max_anoms = 0.2, verbose = FALSE) {

  # Variables
  n <- length(x)
  r <- trunc(n * max_anoms) # use max anoms to limit loop
  R <- numeric(length = r) # test statistics for 'r' outliers

  lambda <- numeric(length = r) # critical values for 'r' outliers
  outlier_ind <- numeric(length = r) # removed outlier observation values
  outlier_val <- numeric(length = r) # removed outlier observation values
  m <- 0 # number of outliers
  x_new <- x # temporary observation values
  median_new <- numeric(length = r)
  mad_new <- numeric(length = r)

  # Outlier detection
  for (i in seq_len(r)) {

    # Compute test statistic
    median_new[i] <- median(x_new)
    mad_new[i] <- mad(x_new)

    z <- abs(x_new - median(x_new)) / (mad(x_new) + .Machine$double.eps) # Z-scores

    max_ind <- which(z == max(z), arr.ind = T)[1] # in case of ties, return first one
    R[i] <- z[max_ind] # max Z-score
    outlier_val[i] <- x_new[max_ind] # removed outlier observation values
    outlier_ind[i] <- which(x_new[max_ind] == x, arr.ind = T)[1] # index of removed outlier observation values
    x_new <- x_new[-max_ind] # remove observation that maximizes |x_i - x_mean|

    # Compute critical values
    p <- 1 - alpha / (2 * (n - i + 1)) # probability
    t_pv <- qt(p, df = (n - i - 1)) # Critical value from Student's t distribution
    lambda[i] <- ((n - i) * t_pv) / (sqrt((n - i - 1 + t_pv^2) * (n - i + 1)))

    # Find exact number of outliers
    # largest 'i' such that R_i > lambda_i
    if (!is.na(R[i]) & !is.na(lambda[i])) { # qt can produce NaNs
      if (R[i] > lambda[i]) {
        m <- i
      }
    }
  }

    vals_tbl <- tibble::tibble(
      rank = as.numeric(1:r),
      index = outlier_ind,
      value = outlier_val,
      test_statistic = R,
      critical_value = lambda,
      median = median_new,
      mad = mad_new,
      limit_lower = median - critical_value * mad,
      limit_upper = critical_value * mad - median
    ) %>%
      dplyr::mutate(
        outlier = ifelse(test_statistic > critical_value, "Yes", "No"),
        direction = dplyr::case_when(
          (outlier == "Yes") & (value > limit_upper) ~ "Up",
          (outlier == "Yes") & (value < limit_lower) ~ "Down",
          TRUE ~ "NA"
        ),
        direction = ifelse(direction == "NA", NA, direction)
      ) %>%
      dplyr::select(-c(test_statistic:mad))

    outlier_index <- vals_tbl %>% dplyr::filter(outlier == "Yes") %>% dplyr::pull(index)
    outlier_idx <- seq_along(x) %in% outlier_index
    outlier_response <- ifelse(outlier_idx == TRUE, "Yes", "No")

    # Critical Limits
    if (any(vals_tbl$outlier == "No")) {
      # Non outliers identified, pick first limit
      limit_tbl <- vals_tbl %>%
        dplyr::filter(outlier == "No") %>%
        dplyr::slice(1)
      limits_vec <- c(
        limit_lower = limit_tbl$limit_lower,
        limit_upper = limit_tbl$limit_upper
      )
    } else {
      # All outliers, pick last limits
      limit_tbl <- vals_tbl %>%
        dplyr::slice(n())
      limits_vec <- c(
        limit_lower = limit_tbl$limit_lower,
        limit_upper = limit_tbl$limit_upper
      )
    }

    # Return results
    if (verbose) {
      outlier_list <- list(
        outlier = outlier_response,
        outlier_idx = outlier_index,
        outlier_vals = vals_tbl %>% dplyr::filter(outlier == "Yes") %>% dplyr::pull(value),
        outlier_direction = vals_tbl %>% dplyr::filter(outlier == "Yes") %>% dplyr::pull(direction),
        critical_limits = limits_vec,
        outlier_report = vals_tbl
      )
      return(outlier_list)
    } else {
      return(outlier_response)
    }
}

