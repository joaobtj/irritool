test_that("calc_kc_curve returns expected structure and dimensions", {
  kc_pts <- c(0.7, 1.0, 0.95)
  stages <- c(15, 20, 20, 10)
  res <- calc_kc_curve(kc_pts, stages, crop = "Lettuce")

  expect_type(res, "list")
  expect_named(res, c("kc_serie", "kc_plot", "kc_data"))
  expect_equal(length(res$kc_serie), sum(stages))
  expect_s3_class(res$kc_data, "tbl_df")
  expect_s3_class(res$kc_plot, "ggplot")
})

test_that("calc_kc_curve verifies endpoint and transition values", {
  kc_pts <- c(0.4, 1.15, 0.6)
  stages <- c(10, 25, 30, 15)
  res <- calc_kc_curve(kc_pts, stages)

  # Initial stage constant
  expect_equal(res$kc_serie[1], 0.4)
  expect_equal(res$kc_serie[10], 0.4)

  # Mid stage constant
  expect_equal(res$kc_serie[10 + 25], 1.15)
  expect_equal(res$kc_serie[10 + 25 + 30], 1.15)

  # Final value
  expect_equal(res$kc_serie[sum(stages)], 0.6)
})

test_that("calc_kc_curve throws informative errors on invalid input", {
  # Incorrect lengths
  expect_error(calc_kc_curve(c(0.7, 1.0), c(15, 20, 20, 10)))
  expect_error(calc_kc_curve(c(0.7, 1.0, 0.9), c(15, 20, 20)))

  # Negative values or NA/Inf
  expect_error(calc_kc_curve(c(0.7, 1.0, 0.9), c(15, -5, 20, 10)))
  expect_error(calc_kc_curve(c(NA, 1.0, 0.9), c(15, 20, 20, 10)))

  # Identical stages violating development / late conditions
  expect_error(calc_kc_curve(c(1.0, 1.0, 0.8), c(15, 20, 20, 10)))
  expect_error(calc_kc_curve(c(0.7, 1.0, 1.0), c(15, 20, 20, 10)))
  expect_error(calc_kc_curve(c(0.7, 1.0, 0.8), c(15, 0, 20, 10)))
})
