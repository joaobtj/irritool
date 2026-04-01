test_that("flow_unit converte corretamente para m3/s (operator = 'div')", {
  # 1 m3/s deve continuar sendo 1
  expect_equal(flow_unit(q = 1, q_unit = "m3/s"), 1)

  # 1000 l/s deve virar 1 m3/s
  expect_equal(flow_unit(q = 1000, q_unit = "l/s"), 1)

  # 3600 m3/h deve virar 1 m3/s
  expect_equal(flow_unit(q = 3600, q_unit = "m3/h"), 1)

  # 3.600.000 l/h deve virar 1 m3/s
  expect_equal(flow_unit(q = 3600000, q_unit = "l/h"), 1)
})

test_that("flow_unit converte corretamente a partir de m3/s (operator = 'mult')", {
  # 1 m3/s deve virar 1000 l/s
  expect_equal(flow_unit(q = 1, q_unit = "l/s", operator = "mult"), 1000)

  # 1 m3/s deve virar 3600 m3/h
  expect_equal(flow_unit(q = 1, q_unit = "m3/h", operator = "mult"), 3600)
})

test_that("flow_unit barra unidades e operadores inválidos", {
  # Testa se o match.arg está funcionando e gerando erro para unidades erradas
  expect_error(flow_unit(q = 10, q_unit = "litros"))
  expect_error(flow_unit(q = 10, q_unit = "m3/s", operator = "soma"))
})
