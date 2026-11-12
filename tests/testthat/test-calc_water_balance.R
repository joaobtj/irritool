test_that("calc_water_balance returns expected structure and columns", {
  et0 <- rep(4, 10)
  rain <- rep(0, 10)
  kc <- rep(1, 10)

  res <- calc_water_balance(
    et0 = et0,
    rainfall = rain,
    daily_kc_values = kc,
    root_depth = 300,
    theta_fc = 0.30,
    theta_wp = 0.15,
    depletion_factor = 0.5
  )

  expect_type(res, "list")
  expect_named(res, c("water_balance_data", "summary_depths"))
  expect_s3_class(res$water_balance_data, "tbl_df")
  expect_equal(nrow(res$water_balance_data), 10)

  expected_cols <- c(
    "day", "rainfall", "et0", "root_depth", "taw", "raw",
    "depletion_start", "kc", "ks", "etc", "depletion_end",
    "irrigation_applied", "water_surplus"
  )
  expect_named(res$water_balance_data, expected_cols)
})

test_that("calc_water_balance handles threshold vs fixed interval rules", {
  # TAW = (0.30 - 0.15) * 200 = 30 mm; RAW = 30 * 0.5 = 15 mm
  # Daily ETc = 5 mm -> exceeds RAW on day 4 (depletion = 20 mm)
  et0 <- rep(5, 8)
  rain <- rep(0, 8)
  kc <- rep(1, 8)

  res_thresh <- calc_water_balance(
    et0 = et0, rainfall = rain, daily_kc_values = kc,
    root_depth = 200, theta_fc = 0.30, theta_wp = 0.15,
    depletion_factor = 0.5, irrigation_rule = "threshold"
  )

  expect_equal(res_thresh$summary_depths$irrigation_events_count, 2)
  expect_equal(res_thresh$water_balance_data$irrigation_applied[4], 20)
  expect_equal(res_thresh$water_balance_data$irrigation_applied[8], 20)

  # Fixed 3-day interval -> irrigates on days 3 and 6
  res_fixed <- calc_water_balance(
    et0 = et0, rainfall = rain, daily_kc_values = kc,
    root_depth = 200, theta_fc = 0.30, theta_wp = 0.15,
    depletion_factor = 0.5, irrigation_rule = 3
  )

  expect_equal(res_fixed$summary_depths$irrigation_events_count, 2)
  expect_equal(res_fixed$water_balance_data$irrigation_applied[3], 15)
  expect_equal(res_fixed$water_balance_data$irrigation_applied[6], 15)
})

test_that("calc_water_balance computes water surplus accurately on excess rain", {
  res <- calc_water_balance(
    et0 = c(2, 2),
    rainfall = c(30, 0),
    daily_kc_values = c(1, 1),
    root_depth = 300,
    theta_fc = 0.30,
    theta_wp = 0.15,
    depletion_factor = 0.5,
    initial_depletion = 0
  )

  expect_equal(res$water_balance_data$water_surplus[1], 28)
  expect_equal(res$water_balance_data$depletion_end[1], 0)
  expect_equal(res$summary_depths$net_rainfall, 2)
})

test_that("calc_water_balance validates invalid inputs", {
  expect_error(
    calc_water_balance(c(4, 4), c(0, 0), c(1), 300, 0.3, 0.15, 0.5)
  )
  expect_error(
    calc_water_balance(c(4, 4), c(0, 0), c(1, 1), 300, 0.15, 0.30, 0.5)
  )
  expect_error(
    calc_water_balance(c(4, 4), c(0, 0), c(1, 1), 300, 0.30, 0.15, 1.2)
  )
  expect_error(
    calc_water_balance(c(4, 4), c(0, 0), c(1, 1), 300, 0.30, 0.15, 0.5, irrigation_rule = "invalid")
  )
  expect_error(
    calc_water_balance(c(4, 4), c(0, 0), c(1, 1), 300, 0.30, 0.15, 0.5, irrigation_rule = -3)
  )
})
