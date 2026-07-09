# =============================================================================
# Test Suite: descriptiveStats
# Functions: calc_mean, calc_median, calc_mode, calc_q1, calc_q3, calc_iqr
# Standards: Edge cases, NA handling, error messages, any-length vectors
# =============================================================================

# Shared test data
data_standard  <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)   # n=10, clear mode=5
data_with_na   <- c(1, 2, NA, 4, NA, 6)                # NA values mid-vector
data_single    <- c(42)                                  # single element
data_two       <- c(3, 7)                               # even n=2
data_large     <- seq(1, 1000)                          # large vector (n=1000)
data_negative  <- c(-10, -5, -3, -1, 0, 2)             # negative values
data_all_same  <- c(7, 7, 7, 7)                         # all identical
data_tie_mode  <- c(1, 1, 2, 2, 3)                     # bimodal tie
data_no_mode   <- c(1, 2, 3)                            # uniform — no mode
data_only_na <- c(NA_real_, NA_real_, NA_real_)        # forces numeric NA
data_decimals  <- c(1.5, 2.5, 3.5, 4.5)               # floating point


# =============================================================================
# calc_mean
# =============================================================================

test_that("calc_mean: correct value on standard vector", {
  expect_equal(calc_mean(data_standard), 4.3)
})

test_that("calc_mean: strips NA and computes on remaining values", {
  expect_equal(calc_mean(data_with_na), mean(c(1, 2, 4, 6)))
})

test_that("calc_mean: single element returns that element", {
  expect_equal(calc_mean(data_single), 42)
})

test_that("calc_mean: two elements returns their average", {
  expect_equal(calc_mean(data_two), 5)
})

test_that("calc_mean: works on large vector (n=1000)", {
  expect_equal(calc_mean(data_large), 500.5)
})

test_that("calc_mean: handles negative values", {
  expect_equal(calc_mean(data_negative), mean(data_negative))
})

test_that("calc_mean: handles decimal values", {
  expect_equal(calc_mean(data_decimals), 3.0)
})

test_that("calc_mean: NULL input throws informative error", {
  expect_error(calc_mean(NULL), "Input vector cannot be empty or NULL.")
})

test_that("calc_mean: empty vector throws informative error", {
  expect_error(calc_mean(c()), "Input vector cannot be empty or NULL.")
})

test_that("calc_mean: non-numeric input throws informative error", {
  expect_error(calc_mean(c("a", "b")), "Input must be a numeric vector.")
})

test_that("calc_mean: all-NA vector throws informative error", {
  expect_error(calc_mean(data_only_na), "Input contains only NA values.")
})


# =============================================================================
# calc_median
# =============================================================================

test_that("calc_median: even-length vector averages two middle values", {
  expect_equal(calc_median(data_standard), 4.5)
})

test_that("calc_median: odd-length vector returns middle value", {
  expect_equal(calc_median(c(1, 3, 5, 7, 9)), 5)
})

test_that("calc_median: single element returns that element", {
  expect_equal(calc_median(data_single), 42)
})

test_that("calc_median: two elements returns their average", {
  expect_equal(calc_median(data_two), 5)
})

test_that("calc_median: strips NA before computing", {
  expect_equal(calc_median(data_with_na), median(c(1, 2, 4, 6)))
})

test_that("calc_median: works on large vector (n=1000)", {
  expect_equal(calc_median(data_large), 500.5)
})

test_that("calc_median: handles negative values", {
  expect_equal(calc_median(data_negative), median(data_negative))
})

test_that("calc_median: NULL input throws informative error", {
  expect_error(calc_median(NULL), "Input vector cannot be empty or NULL.")
})

test_that("calc_median: empty vector throws informative error", {
  expect_error(calc_median(c()), "Input vector cannot be empty or NULL.")
})

test_that("calc_median: non-numeric input throws informative error", {
  expect_error(calc_median(c("x", "y")), "Input must be a numeric vector.")
})

test_that("calc_median: all-NA vector throws informative error", {
  expect_error(calc_median(data_only_na), "Input contains only NA values.")
})


# =============================================================================
# calc_mode
# =============================================================================

test_that("calc_mode: returns single clear mode", {
  expect_equal(calc_mode(data_standard), 5)
})

test_that("calc_mode: returns all modes on bimodal tie", {
  expect_equal(sort(calc_mode(data_tie_mode)), c(1, 2))
})

test_that("calc_mode: all-same vector returns that value", {
  expect_equal(calc_mode(data_all_same), 7)
})

test_that("calc_mode: uniform vector returns NA with message", {
  expect_message(
    result <- calc_mode(data_no_mode),
    "No mode found: all values have equal frequency."
  )
  expect_true(is.na(result))
})

test_that("calc_mode: strips NA before computing mode", {
  expect_equal(calc_mode(c(1, 2, NA, 2, 3)), 2)
})

test_that("calc_mode: single element returns that element", {
  expect_equal(calc_mode(data_single), 42)
})

test_that("calc_mode: works on large vector", {
  v <- c(rep(99, 500), seq(1, 500))
  expect_equal(calc_mode(v), 99)
})

test_that("calc_mode: NULL input throws informative error", {
  expect_error(calc_mode(NULL), "Input vector cannot be empty or NULL.")
})

test_that("calc_mode: empty vector throws informative error", {
  expect_error(calc_mode(c()), "Input vector cannot be empty or NULL.")
})

test_that("calc_mode: non-numeric input throws informative error", {
  expect_error(calc_mode(c("a", "b")), "Input must be a numeric vector.")
})

test_that("calc_mode: all-NA vector throws informative error", {
  expect_error(calc_mode(data_only_na), "Input contains only NA values.")
})


# =============================================================================
# calc_q1
# =============================================================================

test_that("calc_q1: correct Q1 on standard vector", {
  expect_equal(calc_q1(data_standard), as.numeric(quantile(data_standard, 0.25, type = 7)))
})

test_that("calc_q1: strips NA before computing", {
  clean <- c(1, 2, 4, 6)
  expect_equal(calc_q1(data_with_na), as.numeric(quantile(clean, 0.25, type = 7)))
})

test_that("calc_q1: single element returns that element", {
  expect_equal(calc_q1(data_single), 42)
})

test_that("calc_q1: works on large vector (n=1000)", {
  expect_equal(calc_q1(data_large), as.numeric(quantile(data_large, 0.25, type = 7)))
})

test_that("calc_q1: handles negative values", {
  expect_equal(calc_q1(data_negative), as.numeric(quantile(data_negative, 0.25, type = 7)))
})

test_that("calc_q1: NULL input throws informative error", {
  expect_error(calc_q1(NULL), "Input vector cannot be empty or NULL.")
})

test_that("calc_q1: empty vector throws informative error", {
  expect_error(calc_q1(c()), "Input vector cannot be empty or NULL.")
})

test_that("calc_q1: non-numeric input throws informative error", {
  expect_error(calc_q1(c("a", "b")), "Input must be a numeric vector.")
})

test_that("calc_q1: all-NA vector throws informative error", {
  expect_error(calc_q1(data_only_na), "Input contains only NA values.")
})


# =============================================================================
# calc_q3
# =============================================================================

test_that("calc_q3: correct Q3 on standard vector", {
  expect_equal(calc_q3(data_standard), as.numeric(quantile(data_standard, 0.75, type = 7)))
})

test_that("calc_q3: strips NA before computing", {
  clean <- c(1, 2, 4, 6)
  expect_equal(calc_q3(data_with_na), as.numeric(quantile(clean, 0.75, type = 7)))
})

test_that("calc_q3: single element returns that element", {
  expect_equal(calc_q3(data_single), 42)
})

test_that("calc_q3: works on large vector (n=1000)", {
  expect_equal(calc_q3(data_large), as.numeric(quantile(data_large, 0.75, type = 7)))
})

test_that("calc_q3: handles negative values", {
  expect_equal(calc_q3(data_negative), as.numeric(quantile(data_negative, 0.75, type = 7)))
})

test_that("calc_q3: NULL input throws informative error", {
  expect_error(calc_q3(NULL), "Input vector cannot be empty or NULL.")
})

test_that("calc_q3: empty vector throws informative error", {
  expect_error(calc_q3(c()), "Input vector cannot be empty or NULL.")
})

test_that("calc_q3: non-numeric input throws informative error", {
  expect_error(calc_q3(c("a", "b")), "Input must be a numeric vector.")
})

test_that("calc_q3: all-NA vector throws informative error", {
  expect_error(calc_q3(data_only_na), "Input contains only NA values.")
})


# =============================================================================
# calc_iqr
# =============================================================================

test_that("calc_iqr: correct IQR equals Q3 minus Q1", {
  expect_equal(calc_iqr(data_standard), calc_q3(data_standard) - calc_q1(data_standard))
})

test_that("calc_iqr: IQR is zero when all values identical", {
  expect_equal(calc_iqr(data_all_same), 0)
})

test_that("calc_iqr: strips NA before computing", {
  clean <- c(1, 2, 4, 6)
  expect_equal(calc_iqr(data_with_na), calc_iqr(clean))
})

test_that("calc_iqr: single element returns zero IQR", {
  expect_equal(calc_iqr(data_single), 0)
})

test_that("calc_iqr: works on large vector (n=1000)", {
  expect_equal(calc_iqr(data_large), calc_q3(data_large) - calc_q1(data_large))
})

test_that("calc_iqr: handles negative values", {
  expect_equal(calc_iqr(data_negative), calc_q3(data_negative) - calc_q1(data_negative))
})

test_that("calc_iqr: IQR is always non-negative", {
  expect_gte(calc_iqr(data_standard), 0)
  expect_gte(calc_iqr(data_negative), 0)
  expect_gte(calc_iqr(data_decimals), 0)
})

test_that("calc_iqr: NULL input throws informative error", {
  expect_error(calc_iqr(NULL), "Input vector cannot be empty or NULL.")
})

test_that("calc_iqr: empty vector throws informative error", {
  expect_error(calc_iqr(c()), "Input vector cannot be empty or NULL.")
})

test_that("calc_iqr: non-numeric input throws informative error", {
  expect_error(calc_iqr(c("a", "b")), "Input must be a numeric vector.")
})

test_that("calc_iqr: all-NA vector throws informative error", {
  expect_error(calc_iqr(data_only_na), "Input contains only NA values.")
})
