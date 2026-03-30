#' Calculate Daily Soil Water Balance
#'
#' @description
#' Calculates the daily soil water balance for a crop over a specified period.
#' The function accounts for reference evapotranspiration, rainfall, crop coefficients,
#' soil properties, and irrigation rules to estimate actual crop evapotranspiration (ETc),
#' soil water depletion, irrigation needs, and water surplus.
#'
#' @md
#'
#' @param et0 Numeric vector. Daily reference evapotranspiration (mm/day).
#' @param rainfall Numeric vector. Daily rainfall (mm/day).
#' @param daily_kc_values Numeric vector. Daily crop coefficient (Kc) values.
#' @param root_depth Numeric vector or single value. Daily root depth (mm). If a single value is provided, it applies to all days.
#' @param theta_fc Numeric. Volumetric soil water content at field capacity (m³/m³).
#' @param theta_wp Numeric. Volumetric soil water content at wilting point (m³/m³).
#' @param depletion_factor Numeric. The fraction of Total Available Water (TAW) that a crop can extract from the root zone without suffering water stress (the 'p' factor from FAO-56). Must be between 0 and 1.
#' @param initial_depletion Numeric. Initial soil water depletion at the start of day 1 (mm). Defaults to 0 (field capacity).
#' @param day_numbers Numeric vector (optional). Sequence of days (e.g., day of the year). Defaults to a sequence from 1 to the length of `daily_kc_values`.
#' @param irrigation_rule Character or Integer. Defines the irrigation trigger. Use `"threshold"` (default) to irrigate when depletion exceeds Readily Available Water (RAW), or a positive integer `N` to irrigate at a fixed N-day interval.
#'
#' @return A list containing:
#'   \item{water_balance_data}{A data.frame with the detailed daily soil water balance components:
#'     `day`: Day number.
#'     `rainfall`: Input rainfall (mm).
#'     `et0`: Input reference ET0 (mm).
#'     `root_depth`: Root depth for the day (mm).
#'     `taw`: Total Available Water in the root zone (mm).
#'     `raw`: Readily Available Water in the root zone (mm).
#'     `depletion_start`: Soil water depletion at the start of the day (mm).
#'     `kc`: Crop coefficient for the day.
#'     `ks`: Water stress coefficient (0-1).
#'     `etc`: Actual crop evapotranspiration (mm).
#'     `depletion_end`: Soil water depletion at the end of the day before irrigation (mm).
#'     `irrigation_applied`: Irrigation depth applied (mm).
#'     `water_surplus`: Water surplus (deep percolation or runoff) (mm).
#'   }
#'   \item{summary_depths}{A list with cumulative water balance components:
#'     `total_rainfall`: Total input rainfall (mm).
#'     `total_water_surplus`: Total water surplus (mm).
#'     `net_rainfall`: Total rainfall minus total water surplus (mm).
#'     `total_etc`: Total actual crop evapotranspiration (mm).
#'     `total_irrigation_applied`: Total irrigation depth applied (mm).
#'     `irrigation_events_count`: Number of irrigation events.
#'   }
#'
#' @references
#' Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop evapotranspiration - Guidelines for computing crop water requirements. FAO Irrigation and drainage paper 56.
#'
#' @export
#'
#' @examples
#' # For a standalone example, let's create a dummy daily_kc_values
#' daily_kc_lettuce <- c(
#'   rep(0.7, 15),
#'   seq(0.7, 1.05, length.out = 20),
#'   rep(1.05, 20),
#'   seq(1.05, 0.9, length.out = 10)
#' ) # Total 65 days
#'
#' set.seed(123) # for reproducibility
#' sim_days <- length(daily_kc_lettuce)
#' et0_data <- round(runif(sim_days, 2, 5), 1)
#' rain_data <- round(sample(c(rep(0, sim_days - 5), runif(5, 3, 30))), 0)
#'
#' root_depth_val <- 300 # mm
#' p_factor_val <- 0.55
#' theta_fc_val <- 0.30 # m3/m3
#' theta_wp_val <- 0.15 # m3/m3
#'
#' water_balance_results <- calc_water_balance(
#'   et0 = et0_data,
#'   rainfall = rain_data,
#'   daily_kc_values = daily_kc_lettuce,
#'   root_depth = root_depth_val,
#'   theta_fc = theta_fc_val,
#'   theta_wp = theta_wp_val,
#'   depletion_factor = p_factor_val,
#'   initial_depletion = 0, # Starting at field capacity
#'   irrigation_rule = "threshold"
#' )
#'
#' print(head(water_balance_results$water_balance_data))
#' print(water_balance_results$summary_depths)
#'
#' # Example with fixed interval irrigation (every 7 days)
#' water_balance_fixed_interval <- calc_water_balance(
#'   et0 = et0_data,
#'   rainfall = rain_data,
#'   daily_kc_values = daily_kc_lettuce,
#'   root_depth = root_depth_val,
#'   theta_fc = theta_fc_val,
#'   theta_wp = theta_wp_val,
#'   depletion_factor = p_factor_val,
#'   irrigation_rule = 7
#' )
#' print(water_balance_fixed_interval$summary_depths$total_irrigation_applied)
#' print(water_balance_fixed_interval$summary_depths$irrigation_events_count)
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
    stop("et0, rainfall, and daily_kc_values must be numeric vectors.")
  }
  if (!is.numeric(root_depth) || !(length(root_depth) == 1 || length(root_depth) == length(daily_kc_values))) {
    stop("root_depth must be a single numeric value or a numeric vector of the same length as daily_kc_values.")
  }
  if (!is.numeric(theta_fc) || length(theta_fc) != 1 ||
    !is.numeric(theta_wp) || length(theta_wp) != 1 ||
    !is.numeric(depletion_factor) || length(depletion_factor) != 1) {
    stop("theta_fc, theta_wp, and depletion_factor must be single numeric values.")
  }
  if (theta_fc <= theta_wp) {
    stop("Soil moisture at field capacity must be greater than at wilting point.")
  }
  if (depletion_factor <= 0 || depletion_factor >= 1) {
    stop("Depletion factor (p) must be between 0 and 1 (exclusive of 0 and 1, typically).")
  }
  if (!is.numeric(initial_depletion) || length(initial_depletion) != 1) {
    stop("Initial soil depletion must be a single numeric value.")
  }

  # Validate irrigation_rule
  if (is.character(irrigation_rule)) {
    if (irrigation_rule != "threshold") {
      stop("If irrigation_rule is a character, it must be 'threshold'.")
    }
  } else if (is.numeric(irrigation_rule)) {
    if (irrigation_rule <= 0 || irrigation_rule %% 1 != 0) {
      stop("If irrigation_rule is numeric, it must be a positive integer (fixed day interval).")
    }
  } else {
    stop("irrigation_rule must be the string 'threshold' or a positive integer.")
  }

  # Expand day_numbers and root_depth vectors if necessary
  if (is.null(day_numbers)) {
    day_numbers <- seq_along(daily_kc_values)
  }
  if (length(root_depth) == 1) {
    root_depth <- rep(root_depth, length(day_numbers))
  }

  # Verify that all time-series vectors have the same length
  expected_length <- length(daily_kc_values)
  if (length(et0) != expected_length ||
    length(rainfall) != expected_length ||
    length(root_depth) != expected_length ||
    length(day_numbers) != expected_length) {
    stop("All time-series input vectors (et0, rainfall, daily_kc, expanded root_depth, day_numbers) must have the same length.")
  }
  if (initial_depletion < 0) {
    warning("Initial depletion is negative, setting to 0 (field capacity).")
    initial_depletion <- 0
  }


  # --- Initialize Data Frame for Water Balance ---
  wb_df <- data.frame(
    day = day_numbers,
    rainfall = rainfall,
    et0 = et0,
    root_depth = root_depth,
    taw = NA_real_, # Total Available Water (mm)
    raw = NA_real_, # Readily Available Water (mm)
    depletion_start = NA_real_, # Depletion at start of day (mm)
    kc = daily_kc_values,
    ks = NA_real_, # Water Stress Coefficient
    etc = NA_real_, # Actual Crop Evapotranspiration (mm)
    depletion_end = NA_real_, # Depletion at end of day before irrigation (mm)
    irrigation_applied = 0.0, # Initialize irrigation to 0
    water_surplus = NA_real_ # Deep Percolation or Runoff (mm)
  )

  # Calculate Total Available Water (TAW) and Readily Available Water (RAW)
  # These can vary daily if root_depth varies
  wb_df$taw <- (theta_fc - theta_wp) * wb_df$root_depth
  wb_df$raw <- wb_df$taw * depletion_factor

  if (any(initial_depletion > wb_df$taw[1])) {
    warning("Initial depletion (", initial_depletion, "mm) exceeds TAW on day 1 (", round(wb_df$taw[1], 1), "mm). Setting depletion to TAW (wilting point).")
    initial_depletion <- wb_df$taw[1]
  }


  # --- Daily Loop for Water Balance Calculation ---
  for (i in seq_len(nrow(wb_df))) {
    # 1. Depletion at the start of the day (Dr,i-1)
    if (i == 1) {
      wb_df$depletion_start[i] <- initial_depletion
    } else {
      # Depletion from end of previous day, after accounting for previous day's irrigation
      wb_df$depletion_start[i] <- wb_df$depletion_end[i - 1] - wb_df$irrigation_applied[i - 1]
      # Ensure depletion does not go below zero (i.e., soil water content above field capacity)
      # This can happen if previous day's irrigation was more than the depletion.
      # Such surplus from irrigation should be handled in water_surplus of previous day.
      # Here, we just ensure a valid starting point for current day.
      if (wb_df$depletion_start[i] < 0) wb_df$depletion_start[i] <- 0
    }
    # Ensure depletion does not exceed TAW
    wb_df$depletion_start[i] <- min(wb_df$depletion_start[i], wb_df$taw[i])


    # 2. Water Stress Coefficient (Ks)
    # Ks = 1 if Dr <= RAW. Otherwise, Ks = (TAW - Dr) / (TAW - RAW)
    # (TAW - RAW) = TAW * (1 - p)
    if (wb_df$depletion_start[i] < wb_df$raw[i]) {
      wb_df$ks[i] <- 1.0
    } else {
      # Avoid division by zero if TAW is very small or RAW = TAW (p=1, though validated against)
      denominator_ks <- wb_df$taw[i] * (1 - depletion_factor)
      if (denominator_ks > 1e-6 && wb_df$depletion_start[i] < wb_df$taw[i]) { # Ensure not at wilting point for calculation
        wb_df$ks[i] <- (wb_df$taw[i] - wb_df$depletion_start[i]) / denominator_ks
      } else { # At or beyond wilting point, or TAW very small
        wb_df$ks[i] <- 0.0
      }
    }
    wb_df$ks[i] <- max(0, min(1, wb_df$ks[i])) # Ensure Ks is between 0 and 1

    # 3. Actual Crop Evapotranspiration (etc or ETa)
    # etc = Kc * Ks * ET0
    wb_df$etc[i] <- wb_df$et0[i] * wb_df$kc[i] * wb_df$ks[i]

    # 4. Depletion at the end of the day before current day's irrigation (Dr_i)
    # Dr_i = Dr_start_i - Rainfall_i + ETc_actual_i
    # This value can be temporarily negative if Rainfall is high (water content > FC)
    # or greater than TAW if etc is high.
    depletion_before_runoff_check <- wb_df$depletion_start[i] - wb_df$rainfall[i] + wb_df$etc[i]

    # Calculate water surplus (deep percolation/runoff) from rainfall
    # This is water that exceeds field capacity due to rain, after ETc
    daily_surplus_from_rain <- 0
    if (depletion_before_runoff_check < 0) {
      daily_surplus_from_rain <- -depletion_before_runoff_check # Amount of water above FC
      wb_df$depletion_end[i] <- 0 # Depletion is reset to 0 (Field Capacity)
    } else {
      wb_df$depletion_end[i] <- depletion_before_runoff_check
    }
    # Ensure depletion_end does not exceed TAW
    wb_df$depletion_end[i] <- min(wb_df$depletion_end[i], wb_df$taw[i])

    # Initialize today's irrigation and surplus (rain surplus already handled)
    wb_df$irrigation_applied[i] <- 0.0
    # wb_df$water_surplus[i] will accumulate all surplus for the day

    # 5. Determine Irrigation for the current day
    if (irrigation_rule == "threshold") {
      if (wb_df$depletion_end[i] > wb_df$raw[i]) {
        # Irrigate to bring depletion back to 0 (Field Capacity)
        wb_df$irrigation_applied[i] <- wb_df$depletion_end[i]
      }
    } else { # irrigation_rule is a numeric interval
      if (wb_df$day[i] %% irrigation_rule == 0) {
        # Irrigate to bring depletion back to 0 (Field Capacity)
        wb_df$irrigation_applied[i] <- wb_df$depletion_end[i]
      }
    }

    # 6. Calculate total daily water surplus (Deep Percolation / Runoff)
    wb_df$water_surplus[i] <- daily_surplus_from_rain
  }

  # --- Summarize Results ---
  summary_depths_list <- list(
    total_rainfall = sum(wb_df$rainfall, na.rm = TRUE),
    total_water_surplus = sum(wb_df$water_surplus, na.rm = TRUE),
    # net_rainfall is total rain that didn't become immediate surplus from rain
    net_rainfall = sum(wb_df$rainfall, na.rm = TRUE) - sum(wb_df$water_surplus, na.rm = TRUE),
    total_etc = sum(wb_df$etc, na.rm = TRUE),
    total_irrigation_applied = sum(wb_df$irrigation_applied, na.rm = TRUE),
    irrigation_events_count = sum(wb_df$irrigation_applied > 1e-6, na.rm = TRUE) # Count events with minimal irrigation
  )

  return(
    list(
      water_balance_data = wb_df,
      summary_depths = summary_depths_list
    )
  )
}
