test_that("Curva Kc gera o comprimento correto de dias e valores", {
  kc_pts <- c(0.7, 1.0, 0.95)
  stages <- c(10, 20, 15, 5) # Total de 50 dias

  resultado <- calc_kc_curve(kc_points = kc_pts, stage_lengths = stages, crop = "Teste")

  # Verificar se a série temporal tem 50 dias
  expect_length(resultado$kc_serie, 50)

  # Verificar se o primeiro dia tem o valor de Kc_ini (0.7)
  expect_equal(resultado$kc_serie[1], 0.7)

  # Verificar se a estrutura de saída é uma lista com os 3 elementos esperados
  expect_named(resultado, c("kc_serie", "kc_plot", "kc_data"))

  # Verificar se o gráfico é da classe ggplot
  expect_s3_class(resultado$kc_plot, "ggplot")
})

test_that("Fases com comprimento zero devolvem erros quando aplicável", {
  # Se kc_ini for diferente de kc_mid, a fase de desenvolvimento NÃO pode ser zero
  expect_error(
    calc_kc_curve(kc_points = c(0.7, 1.0, 0.95), stage_lengths = c(10, 0, 15, 5)),
    "Development phase length"
  )
})
