#' Calculate Daily Soil Water Balance
#'
#' @description
#' Calculates the daily soil water balance for a crop over a specified period.
#' The function accounts for reference evapotranspiration, rainfall, crop coefficients,
#' soil properties, and irrigation rules to estimate actual crop evapotranspiration (ETc),
#' soil water depletion, irrigation needs, and water surplus.
#'
#' @param et0 Numeric vector. Daily reference evapotranspiration (mm/day).
#' @param rainfall Numeric vector. Daily rainfall (mm/day).
#' @param daily_kc_values Numeric vector. Daily crop coefficient (\eqn{K_c}) values.
#' @param root_depth Numeric vector or single value. Daily root depth (mm). If a
#'   single value is provided, it applies to all days.
#' @param theta_fc Numeric. Volumetric soil water content at field capacity (\eqn{\text{m}^3/\text{m}^3}).
#' @param theta_wp Numeric. Volumetric soil water content at wilting point (\eqn{\text{m}^3/\text{m}^3}).
#' @param depletion_factor Numeric. The fraction of Total Available Water (TAW)
#'   that a crop can extract from the root zone without suffering water stress
#'   (the `p` factor from FAO-56). Must be strictly between 0 and 1.
#' @param initial_depletion Numeric. Initial soil water depletion at the start of
#'   day 1 (mm). Defaults to `0` (field capacity).
#' @param day_numbers Numeric vector (optional). Sequence of days (e.g., day of the year).
#'   Defaults to a sequence from `1` to the length of `daily_kc_values`.
#' @param irrigation_rule Character or integer. Defines the irrigation trigger. Use
#'   `"threshold"` (default) to irrigate when depletion exceeds Readily Available
#'   Water (RAW), or a positive integer `N` to irrigate at a fixed N-day interval.
#'
#' @return A named `list` containing:
#' * `water_balance_data`: A [tibble::tibble()] with daily soil water balance components:
#'   `day`, `rainfall`, `et0`, `root_depth`, `taw`, `raw`, `depletion_start`, `kc`,
#'   `ks`, `etc`, `depletion_end`, `irrigation_applied`, and `water_surplus`.
#' * `summary_depths`: A named `list` with cumulative totals: `total_rainfall`,
#'   `total_water_surplus`, `net_rainfall`, `total_etc`, `total_irrigation_applied`,
#'   and `irrigation_events_count`.
#'
#' @references
#' Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop
#' evapotranspiration - Guidelines for computing crop water requirements. FAO
#' Irrigation and drainage paper 56. Food and Agriculture Organization of the
#' United Nations, Rome.
#'
#' @importFrom rlang abort warn
#' @importFrom tibble tibble
#'
#' @export
#'
#' @examples
#' kc_lettuce <- calc_kc_curve(
#'   kc_points = c(0.7, 1.05, 0.9),
#'   stage_lengths = c(15, 20, 20, 10)
#' )$kc_serie
#'
#' set.seed(123)
#' sim_days <- length(kc_lettuce)
#' et0_data <- round(runif(sim_days, 2, 5), 1)
#' rain_data <- round(sample(c(rep(0, sim_days - 5), runif(5, 3, 30))), 0)
#'
#' wb_threshold <- calc_water_balance(
#'   et0 = et0_data,
#'   rainfall = rain_data,
#'   daily_kc_values = kc_lettuce,
#'   root_depth = 300,
#'   theta_fc = 0.30,
#'   theta_wp = 0.15,
#'   depletion_factor = 0.55,
#'   irrigation_rule = "threshold"
#' )
#'
#' print(head(wb_threshold$water_balance_data))
#' print(wb_threshold$summary_depths)
#'
#' # Fixed interval irrigation (every 7 days)
#' wb_fixed <- calc_water_balance(
#'   et0 = et0_data,
#'   rainfall = rain_data,
#'   daily_kc_values = kc_lettuce,
#'   root_depth = 300,
#'   theta_fc = 0.30,
#'   theta_wp = 0.15,
#'   depletion_factor = 0.55,
#'   irrigation_rule = 7
#' )
#'
#' print(wb_fixed$summary_depths$irrigation_events_count)
calc_water_balance <- function(et0,
                               rainfall,
                               daily_kc_values,
                               root_depth,
                               theta_fc,
                               theta_wp,
                               depletion_factor,
                               initial_depletion = 0,
                               day_numbers = NULL,
                               irrigation_rule = "threshold") {
  # --- Input Validation ---
  if (!is.numeric(et0) || !is.numeric(rainfall) || !is.numeric(daily_kc_values)) {
    rlang::abort("`et0`, `rainfall`, and `daily_kc_values` must be numeric vectors.")
  }

  n_days <- length(daily_kc_values)
  if (!is.numeric(root_depth) || !(length(root_depth) == 1L || length(root_depth) == n_days)) {
    rlang::abort("`root_depth` must be a single numeric value or match the length of `daily_kc_values`.")
  }

  if (!is.numeric(theta_fc) || length(theta_fc) != 1L ||
      !is.numeric(theta_wp) || length(theta_wp) != 1L ||
      !is.numeric(depletion_factor) || length(depletion_factor) != 1L) {
    rlang::abort("`theta_fc`, `theta_wp`, and `depletion_factor` must be single numeric values.")
  }

  if (theta_fc <= theta_wp) {
    rlang::abort("`theta_fc` (field capacity) must be strictly greater than `theta_wp` (wilting point).")
  }

  if (depletion_factor <= 0 || depletion_factor >= 1) {
    rlang::abort("`depletion_factor` (p) must be strictly between 0 and 1.")
  }

  if (!is.numeric(initial_depletion) || length(initial_depletion) != 1L) {
    rlang::abort("`initial_depletion` must be a single numeric value.")
  }

  if (is.character(irrigation_rule)) {
    if (length(irrigation_rule) != 1L || irrigation_rule != "threshold") {
      rlang::abort("When character, `irrigation_rule` must be 'threshold'.")
    }
  } else if (is.numeric(irrigation_rule)) {
    if (length(irrigation_rule) != 1L || irrigation_rule <= 0 || irrigation_rule %% 1 != 0) {
      rlang::abort("When numeric, `irrigation_rule` must be a single positive integer.")
    }
  } else {
    rlang::abort("`irrigation_rule` must be 'threshold' or a positive integer.")
  }

  if (is.null(day_numbers)) {
    day_numbers <- seq_len(n_days)
  }

  if (length(root_depth) == 1L) {
    root_depth <- rep(root_depth, n_days)
  }

  if (length(et0) != n_days ||
      length(rainfall) != n_days ||
      length(root_depth) != n_days ||
      length(day_numbers) != n_days) {
    rlang::abort("All time-series vectors (`et0`, `rainfall`, `daily_kc_values`, `root_depth`, `day_numbers`) must share identical lengths.")
  }

  if (initial_depletion < 0) {
    rlang::warn("`initial_depletion` is negative; resetting to 0 (field capacity).")
    initial_depletion <- 0
  }

  # --- Initialize Water Balance Table ---
  taw <- (theta_fc - theta_wp) * root_depth
  raw <- taw * depletion_factor

  if (initial_depletion > taw[1]) {
    rlang::warn(
      paste0(
        "`initial_depletion` (", initial_depletion, " mm) exceeds day 1 TAW (",
        round(taw[1], 1), " mm); capping at TAW."
      )
    )
    initial_depletion <- taw[1]
  }

  depletion_start <- numeric(n_days)
  ks <- numeric(n_days)
  etc <- numeric(n_days)
  depletion_end <- numeric(n_days)
  irrigation_applied <- numeric(n_days)
  water_surplus <- numeric(n_days)

  # --- Daily Simulation Loop ---
  for (i in seq_len(n_days)) {
    if (i == 1L) {
      d_start <- initial_depletion
    } else {
      d_start <- depletion_end[i - 1L] - irrigation_applied[i - 1L]
      if (d_start < 0) d_start <- 0
    }
    d_start <- min(d_start, taw[i])
    depletion_start[i] <- d_start

    # Water Stress Coefficient (Ks)
    if (d_start < raw[i]) {
      current_ks <- 1.0
    } else {
      denom_ks <- taw[i] * (1 - depletion_factor)
      if (denom_ks > 1e-6 && d_start < taw[i]) {
        current_ks <- (taw[i] - d_start) / denom_ks
      } else {
        current_ks <- 0.0
      }
    }
    ks[i] <- max(0, min(1, current_ks))

    # Actual Crop Evapotranspiration
    etc[i] <- et0[i] * daily_kc_values[i] * ks[i]

    # End-of-day depletion prior to irrigation
    d_raw_end <- d_start - rainfall[i] + etc[i]

    if (d_raw_end < 0) {
      water_surplus[i] <- -d_raw_end
      d_end <- 0
    } else {
      water_surplus[i] <- 0
      d_end <- min(d_raw_end, taw[i])
    }
    depletion_end[i] <- d_end

    # Irrigation scheduling rule
    if (identical(irrigation_rule, "threshold")) {
      if (d_end > raw[i]) {
        irrigation_applied[i] <- d_end
      }
    } else {
      if (day_numbers[i] %% irrigation_rule == 0) {
        irrigation_applied[i] <- d_end
      }
    }
  }

  wb_tbl <- tibble::tibble(
    day = day_numbers,
    rainfall = rainfall,
    et0 = et0,
    root_depth = root_depth,
    taw = taw,
    raw = raw,
    depletion_start = depletion_start,
    kc = daily_kc_values,
    ks = ks,
    etc = etc,
    depletion_end = depletion_end,
    irrigation_applied = irrigation_applied,
    water_surplus = water_surplus
  )

  total_rain <- sum(rainfall, na.rm = TRUE)
  total_surplus <- sum(water_surplus, na.rm = TRUE)

  summary_depths_list <- list(
    total_rainfall = total_rain,
    total_water_surplus = total_surplus,
    net_rainfall = total_rain - total_surplus,
    total_etc = sum(etc, na.rm = TRUE),
    total_irrigation_applied = sum(irrigation_applied, na.rm = TRUE),
    irrigation_events_count = sum(irrigation_applied > 1e-6, na.rm = TRUE)
  )

  list(
    water_balance_data = wb_tbl,
    summary_depths = summary_depths_list
  )
}
