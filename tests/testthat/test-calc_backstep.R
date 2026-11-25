test_that("flow_unit produces consistent pressure_head and head_loss", {
  res_m3s <- calc_backstep(
    end_pressure = 10,
    diameter = 0.012,
    spacing = 0.3,
    n_emitters = 12,
    emitter_coef = 3.18 / 3.6e6,
    emitter_exp = 0.5,
    method = "darcy",
    flow_unit = "m3/s",
    roughness = 1.5e-6
  )

  res_lh <- calc_backstep(
    end_pressure = 10,
    diameter = 0.012,
    spacing = 0.3,
    n_emitters = 12,
    emitter_coef = 3.18,
    emitter_exp = 0.5,
    method = "darcy",
    flow_unit = "L/h",
    roughness = 1.5e-6
  )

  expect_equal(res_lh$pressure_head, res_m3s$pressure_head, tolerance = 1e-8)
  expect_equal(res_lh$head_loss, res_m3s$head_loss, tolerance = 1e-8)
  expect_equal(res_lh$emitter_flow, res_m3s$emitter_flow * 3.6e6, tolerance = 1e-8)
})

test_that("method supports flamant and hw with extra arguments via ...", {
  res_flamant <- calc_backstep(
    end_pressure = 10,
    diameter = 0.012,
    spacing = 0.3,
    n_emitters = 10,
    emitter_coef = 2.0,
    emitter_exp = 0.5,
    method = "flamant",
    flow_unit = "L/h",
    coef = 0.000135
  )

  res_hw <- calc_backstep(
    end_pressure = 15,
    diameter = 0.025,
    spacing = 6,
    n_emitters = 5,
    emitter_coef = 0.05,
    emitter_exp = 0.5,
    method = "hw",
    flow_unit = "L/s",
    coef = 150
  )

  expect_s3_class(res_flamant, "tbl_df")
  expect_s3_class(res_hw, "tbl_df")
  expect_true(all(res_flamant$head_loss >= 0))
  expect_true(all(res_hw$head_loss >= 0))
})
