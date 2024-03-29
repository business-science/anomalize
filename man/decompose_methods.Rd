% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/time_decompose_methods.R
\name{decompose_methods}
\alias{decompose_methods}
\alias{decompose_twitter}
\alias{decompose_stl}
\title{Methods that power time_decompose()}
\usage{
decompose_twitter(
  data,
  target,
  frequency = "auto",
  trend = "auto",
  message = TRUE
)

decompose_stl(data, target, frequency = "auto", trend = "auto", message = TRUE)
}
\arguments{
\item{data}{A \code{tibble} or \code{tbl_time} object.}

\item{target}{A column to apply the function to}

\item{frequency}{Controls the seasonal adjustment (removal of seasonality).
Input can be either "auto", a time-based definition (e.g. "1 week"),
or a numeric number of observations per frequency (e.g. 10).
Refer to \code{\link[=time_frequency]{time_frequency()}}.}

\item{trend}{Controls the trend component
For stl, the trend controls the sensitivity of the lowess smoother, which is used to remove the remainder.
For twitter, the trend controls the period width of the median, which are used to remove the trend and center the remainder.}

\item{message}{A boolean. If \code{TRUE}, will output information related to \code{tbl_time} conversions, frequencies,
and trend / median spans (if applicable).}
}
\value{
A \code{tbl_time} object containing the time series decomposition.
}
\description{
Methods that power time_decompose()
}
\examples{

library(dplyr)

tidyverse_cran_downloads \%>\%
    ungroup() \%>\%
    filter(package == "tidyquant") \%>\%
    decompose_stl(count)


}
\references{
\itemize{
\item The "twitter" method is used in Twitter's \href{https://github.com/twitter/AnomalyDetection}{\code{AnomalyDetection} package}
}
}
\seealso{
\code{\link[=time_decompose]{time_decompose()}}
}
