test_that("Cálculo matemático de TAW e RAW está correto", {
  # Definir inputs simples para um dia
  et0 <- 4.0
  rainfall <- 0.0
  kc <- 1.0
  root_depth <- 300
  theta_fc <- 0.30
  theta_wp <- 0.15
  p_factor <- 0.50

  resultado <- calc_water_balance(
    et0 = et0, rainfall = rainfall, daily_kc_values = kc,
    root_depth = root_depth, theta_fc = theta_fc, theta_wp = theta_wp,
    depletion_factor = p_factor, irrigation_rule = "threshold"
  )

  df <- resultado$water_balance_data

  # TAW esperado: (0.30 - 0.15) * 300 = 45 mm
  expect_equal(df$taw[1], 45)

  # RAW esperado: 45 * 0.50 = 22.5 mm
  expect_equal(df$raw[1], 22.5)

  # Como a depleção inicial é 0 e não choveu, a depleção final deve ser igual à ETc
  # ETc = ET0 * Kc * Ks = 4.0 * 1.0 * 1.0 = 4.0
  expect_equal(df$depletion_end[1], 4.0)
})

test_that("Função devolve erros com inputs inválidos", {
  # Testar se a função para quando a Capacidade de Campo é menor que o Ponto de Murcha
  expect_error(
    calc_water_balance(
      et0 = 4, rainfall = 0, daily_kc_values = 1, root_depth = 300,
      theta_fc = 0.10, theta_wp = 0.15, depletion_factor = 0.5 # FC < WP
    ),
    "Soil moisture at field capacity must be greater than at wilting point"
  )

  # Testar vetores com comprimentos diferentes
  expect_error(
    calc_water_balance(
      et0 = c(4, 5), rainfall = 0, daily_kc_values = 1, # et0 tem tamanho 2, rainfall 1
      root_depth = 300, theta_fc = 0.30, theta_wp = 0.15, depletion_factor = 0.5
    ),
    "All time-series input vectors"
  )
})
