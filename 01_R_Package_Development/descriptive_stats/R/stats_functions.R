validate_numeric_input <- function(x) {
  if (is.null(x) || length(x) == 0) stop("Input vector cannot be empty or NULL.")
  if (!is.numeric(x)) stop("Input must be a numeric vector.")
  x_clean <- x[!is.na(x)]
  if (length(x_clean) == 0) stop("Input contains only NA values.")
  return(x_clean)
}

#' Calculate Arithmetic Mean
#'
#' Computes the arithmetic mean of a numeric vector. Automatically filters out missing (NA) values.
#' Throws an error if the input vector is empty, NULL, non-numeric, or contains only NA entries.
#'
#' @param x A numeric vector.
#' @return A numeric scalar representing the mean.
#' @examples
#' data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
#' calc_mean(data)
#' calc_mean(c(1, 2, NA, 4))
#' @export
calc_mean <- function(x) {
  x_clean <- validate_numeric_input(x)
  return(sum(x_clean) / length(x_clean))
}

#' Calculate Median
#'
#' Computes the median value of a numeric vector. Automatically filters out missing (NA) values.
#' Throws an error if the input vector is empty, NULL, non-numeric, or contains only NA entries.
#'
#' @param x A numeric vector.
#' @return A numeric scalar representing the median.
#' @examples
#' data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
#' calc_median(data)
#' calc_median(c(5))
#' @export
calc_median <- function(x) {
  x_clean <- validate_numeric_input(x)
  n <- length(x_clean)
  sorted_x <- sort(x_clean)
  if (n %% 2 == 1) return(sorted_x[(n + 1) / 2])
  return((sorted_x[n / 2] + sorted_x[(n / 2) + 1]) / 2)
}

#' Calculate Mode
#'
#' Computes the mode(s) of a numeric vector. Returns all modes in case of a tie.
#' Displays a message and returns NA if all values appear with equal frequency.
#' Automatically filters out missing (NA) values.
#'
#' @param x A numeric vector.
#' @return A numeric vector of the most frequent value(s), or NA.
#' @examples
#' data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
#' calc_mode(data)
#' calc_mode(c(1, 1, 2, 2, 3))
#' calc_mode(c(1, 2, 3))
#' @export
calc_mode <- function(x) {
  x_clean <- validate_numeric_input(x)
  counts <- table(x_clean)
  max_count <- max(counts)
  if (all(counts == max_count) && length(counts) > 1) {
    message("No mode found: all values have equal frequency.")
    return(NA_real_)
  }
  return(as.numeric(names(counts)[counts == max_count]))
}

#' Calculate First Quartile (Q1)
#'
#' Computes the 25th percentile (Q1) using Type 7 quantile algorithm. Automatically filters out missing (NA) values.
#' Throws an error if the input vector is empty, NULL, non-numeric, or contains only NA entries.
#'
#' @param x A numeric vector.
#' @return A numeric scalar representing Q1.
#' @examples
#' data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
#' calc_q1(data)
#' @export
calc_q1 <- function(x) {
  x_clean <- validate_numeric_input(x)
  return(as.numeric(stats::quantile(x_clean, 0.25, type = 7)))
}

#' Calculate Third Quartile (Q3)
#'
#' Computes the 75th percentile (Q3) using Type 7 quantile algorithm. Automatically filters out missing (NA) values.
#' Throws an error if the input vector is empty, NULL, non-numeric, or contains only NA entries.
#'
#' @param x A numeric vector.
#' @return A numeric scalar representing Q3.
#' @examples
#' data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
#' calc_q3(data)
#' @export
calc_q3 <- function(x) {
  x_clean <- validate_numeric_input(x)
  return(as.numeric(stats::quantile(x_clean, 0.75, type = 7)))
}

#' Calculate Interquartile Range (IQR)
#'
#' Computes the difference between the third and first quartiles (Q3 - Q1). Automatically filters out missing (NA) values.
#' Throws an error if the input vector is empty, NULL, non-numeric, or contains only NA entries.
#'
#' @param x A numeric vector.
#' @return A numeric scalar representing the IQR.
#' @examples
#' data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
#' calc_iqr(data)
#' @export
calc_iqr <- function(x) {
  return(calc_q3(x) - calc_q1(x))
}
