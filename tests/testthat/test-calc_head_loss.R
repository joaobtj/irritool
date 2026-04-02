test_that("calc_head_loss retorna valores corretos para diferentes métodos", {

  # Parâmetros base para o teste
  d_test <- 50e-3
  q_test <- 10
  q_unit_test <- "m3/h"
  l_test <- 100

  # 1. Colebrook-White (Default)
  res_cb <- calc_head_loss(diameter = d_test, flow_rate = q_test, flow_unit = q_unit_test, length = l_test)
  expect_equal(res_cb, 3.985144, tolerance = 1e-4)

  # 2. Hazen-Williams
  res_hw <- calc_head_loss(diameter = d_test, flow_rate = q_test, flow_unit = q_unit_test, length = l_test, method = "hazen_williams")
  expect_equal(res_hw, 4.521465, tolerance = 1e-4)

  # 3. Swamee-Jain
  res_sj <- calc_head_loss(diameter = d_test, flow_rate = q_test, flow_unit = q_unit_test, length = l_test, method = "swamee_jain")
  expect_equal(res_sj, 3.961843, tolerance = 1e-4)

  # 4. Blasius
  res_bl <- calc_head_loss(diameter = d_test, flow_rate = q_test, flow_unit = q_unit_test, length = l_test, method = "blasius")
  expect_equal(res_bl, 3.968018, tolerance = 1e-4)

  # 5. Haaland
  res_ha <- calc_head_loss(diameter = d_test, flow_rate = q_test, flow_unit = q_unit_test, length = l_test, method = "haaland")
  expect_equal(res_ha, 3.941947, tolerance = 1e-4)
})
