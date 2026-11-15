test_that("calc_backstep computes monotonic pressure increase on flat terrain", {
  res <- calc_backstep(
    end_pressure = 10,
    diameter = 0.012,
    spacing = 0.3,
    n_emitters = 10,
    slope = 0,
    emitter_coef = 8.84e-7,
    emitter_exp = 0.50,
    roughness = 1.5e-6
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 10)
  expect_named(res, c("emitter", "pressure_head", "emitter_flow", "section_flow", "head_loss"))

  expect_equal(res$pressure_head[10], 10)
  expect_equal(res$head_loss[10], 0)
  expect_true(all(diff(res$pressure_head) < 0))
  expect_equal(res$section_flow[1], sum(res$emitter_flow), tolerance = 1e-10)
})

test_that("calc_backstep errors when neither roughness nor friction_factor is supplied", {
  expect_error(
    calc_backstep(
      end_pressure = 10,
      diameter = 0.012,
      spacing = 1,
      n_emitters = 5,
      emitter_coef = 8.84e-7,
      emitter_exp = 0.50
    ),
    "roughness|friction_factor"
  )
})

test_that("calc_backstep validates input arguments", {
  expect_error(
    calc_backstep(10, 0.012, 1, n_emitters = 1, emitter_coef = 8.84e-7, emitter_exp = 0.5, roughness = 1.5e-6)
  )
  expect_error(
    calc_backstep(10, 0.012, 1, n_emitters = 5, emitter_coef = 8.84e-7, emitter_exp = 1.2, roughness = 1.5e-6)
  )
  expect_error(
    calc_backstep(10, 0.012, c(0.3, 0.5), n_emitters = 5, emitter_coef = 8.84e-7, emitter_exp = 0.5, roughness = 1.5e-6)
  )
})
