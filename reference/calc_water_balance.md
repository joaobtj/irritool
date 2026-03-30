# Calculate Daily Soil Water Balance

Calculates the daily soil water balance for a crop over a specified
period. The function accounts for reference evapotranspiration,
rainfall, crop coefficients, soil properties, and irrigation rules to
estimate actual crop evapotranspiration (ETc), soil water depletion,
irrigation needs, and water surplus.

## Usage

``` r
calc_water_balance(
  et0,
  rainfall,
  daily_kc_values,
  root_depth,
  theta_fc,
  theta_wp,
  depletion_factor,
  initial_depletion = 0,
  day_numbers = NULL,
  irrigation_rule = "threshold"
)
```

## Arguments

- et0:

  Numeric vector. Daily reference evapotranspiration (mm/day).

- rainfall:

  Numeric vector. Daily rainfall (mm/day).

- daily_kc_values:

  Numeric vector. Daily crop coefficient (Kc) values.

- root_depth:

  Numeric vector or single value. Daily root depth (mm). If a single
  value is provided, it applies to all days.

- theta_fc:

  Numeric. Volumetric soil water content at field capacity (m³/m³).

- theta_wp:

  Numeric. Volumetric soil water content at wilting point (m³/m³).

- depletion_factor:

  Numeric. The fraction of Total Available Water (TAW) that a crop can
  extract from the root zone without suffering water stress (the 'p'
  factor from FAO-56). Must be between 0 and 1.

- initial_depletion:

  Numeric. Initial soil water depletion at the start of day 1 (mm).
  Defaults to 0 (field capacity).

- day_numbers:

  Numeric vector (optional). Sequence of days (e.g., day of the year).
  Defaults to a sequence from 1 to the length of `daily_kc_values`.

- irrigation_rule:

  Character or Integer. Defines the irrigation trigger. Use
  `"threshold"` (default) to irrigate when depletion exceeds Readily
  Available Water (RAW), or a positive integer `N` to irrigate at a
  fixed N-day interval.

## Value

A list containing:

- water_balance_data:

  A data.frame with the detailed daily soil water balance components:
  `day`: Day number. `rainfall`: Input rainfall (mm). `et0`: Input
  reference ET0 (mm). `root_depth`: Root depth for the day (mm). `taw`:
  Total Available Water in the root zone (mm). `raw`: Readily Available
  Water in the root zone (mm). `depletion_start`: Soil water depletion
  at the start of the day (mm). `kc`: Crop coefficient for the day.
  `ks`: Water stress coefficient (0-1). `etc`: Actual crop
  evapotranspiration (mm). `depletion_end`: Soil water depletion at the
  end of the day before irrigation (mm). `irrigation_applied`:
  Irrigation depth applied (mm). `water_surplus`: Water surplus (deep
  percolation or runoff) (mm).

- summary_depths:

  A list with cumulative water balance components: `total_rainfall`:
  Total input rainfall (mm). `total_water_surplus`: Total water surplus
  (mm). `net_rainfall`: Total rainfall minus total water surplus (mm).
  `total_etc`: Total actual crop evapotranspiration (mm).
  `total_irrigation_applied`: Total irrigation depth applied (mm).
  `irrigation_events_count`: Number of irrigation events.

## References

Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop
evapotranspiration - Guidelines for computing crop water requirements.
FAO Irrigation and drainage paper 56.

## Examples

``` r
# For a standalone example, let's create a dummy daily_kc_values
daily_kc_lettuce <- c(
  rep(0.7, 15),
  seq(0.7, 1.05, length.out = 20),
  rep(1.05, 20),
  seq(1.05, 0.9, length.out = 10)
) # Total 65 days

set.seed(123) # for reproducibility
sim_days <- length(daily_kc_lettuce)
et0_data <- round(runif(sim_days, 2, 5), 1)
rain_data <- round(sample(c(rep(0, sim_days - 5), runif(5, 3, 30))), 0)

root_depth_val <- 300 # mm
p_factor_val <- 0.55
theta_fc_val <- 0.30 # m3/m3
theta_wp_val <- 0.15 # m3/m3

water_balance_results <- calc_water_balance(
  et0 = et0_data,
  rainfall = rain_data,
  daily_kc_values = daily_kc_lettuce,
  root_depth = root_depth_val,
  theta_fc = theta_fc_val,
  theta_wp = theta_wp_val,
  depletion_factor = p_factor_val,
  initial_depletion = 0, # Starting at field capacity
  irrigation_rule = "threshold"
)

print(head(water_balance_results$water_balance_data))
#>   day rainfall et0 root_depth taw   raw depletion_start  kc ks  etc
#> 1   1        0 2.9        300  45 24.75            0.00 0.7  1 2.03
#> 2   2        0 4.4        300  45 24.75            2.03 0.7  1 3.08
#> 3   3        0 3.2        300  45 24.75            5.11 0.7  1 2.24
#> 4   4        0 4.6        300  45 24.75            7.35 0.7  1 3.22
#> 5   5        0 4.8        300  45 24.75           10.57 0.7  1 3.36
#> 6   6        0 2.1        300  45 24.75           13.93 0.7  1 1.47
#>   depletion_end irrigation_applied water_surplus
#> 1          2.03                  0             0
#> 2          5.11                  0             0
#> 3          7.35                  0             0
#> 4         10.57                  0             0
#> 5         13.93                  0             0
#> 6         15.40                  0             0
print(water_balance_results$summary_depths)
#> $total_rainfall
#> [1] 104
#> 
#> $total_water_surplus
#> [1] 58.67
#> 
#> $net_rainfall
#> [1] 45.33
#> 
#> $total_etc
#> [1] 203.7632
#> 
#> $total_irrigation_applied
#> [1] 158.4332
#> 
#> $irrigation_events_count
#> [1] 6
#> 

# Example with fixed interval irrigation (every 7 days)
water_balance_fixed_interval <- calc_water_balance(
  et0 = et0_data,
  rainfall = rain_data,
  daily_kc_values = daily_kc_lettuce,
  root_depth = root_depth_val,
  theta_fc = theta_fc_val,
  theta_wp = theta_wp_val,
  depletion_factor = p_factor_val,
  irrigation_rule = 7
)
print(water_balance_fixed_interval$summary_depths$total_irrigation_applied)
#> [1] 142.4415
print(water_balance_fixed_interval$summary_depths$irrigation_events_count)
#> [1] 8
```
