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

  Numeric vector. Daily crop coefficient (\\K_c\\) values.

- root_depth:

  Numeric vector or single value. Daily root depth (mm). If a single
  value is provided, it applies to all days.

- theta_fc:

  Numeric. Volumetric soil water content at field capacity
  (\\\text{m}^3/\text{m}^3\\).

- theta_wp:

  Numeric. Volumetric soil water content at wilting point
  (\\\text{m}^3/\text{m}^3\\).

- depletion_factor:

  Numeric. The fraction of Total Available Water (TAW) that a crop can
  extract from the root zone without suffering water stress (the `p`
  factor from FAO-56). Must be strictly between 0 and 1.

- initial_depletion:

  Numeric. Initial soil water depletion at the start of day 1 (mm).
  Defaults to `0` (field capacity).

- day_numbers:

  Numeric vector (optional). Sequence of days (e.g., day of the year).
  Defaults to a sequence from `1` to the length of `daily_kc_values`.

- irrigation_rule:

  Character or integer. Defines the irrigation trigger. Use
  `"threshold"` (default) to irrigate when depletion exceeds Readily
  Available Water (RAW), or a positive integer `N` to irrigate at a
  fixed N-day interval.

## Value

A named `list` containing:

- `water_balance_data`: A
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  with daily soil water balance components: `day`, `rainfall`, `et0`,
  `root_depth`, `taw`, `raw`, `depletion_start`, `kc`, `ks`, `etc`,
  `depletion_end`, `irrigation_applied`, and `water_surplus`.

- `summary_depths`: A named `list` with cumulative totals:
  `total_rainfall`, `total_water_surplus`, `net_rainfall`, `total_etc`,
  `total_irrigation_applied`, and `irrigation_events_count`. 88

## References

Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop
evapotranspiration - Guidelines for computing crop water requirements.
FAO Irrigation and drainage paper 56. Food and Agriculture Organization
of the United Nations, Rome.

## Examples

``` r
kc_lettuce <- calc_kc_curve(
  kc_points = c(0.7, 1.05, 0.9),
  stage_lengths = c(15, 20, 20, 10)
)$kc_serie

set.seed(123)
sim_days <- length(kc_lettuce)
et0_data <- round(runif(sim_days, 2, 5), 1)
rain_data <- round(sample(c(rep(0, sim_days - 5), runif(5, 3, 30))), 0)

wb_threshold <- calc_water_balance(
  et0 = et0_data,
  rainfall = rain_data,
  daily_kc_values = kc_lettuce,
  root_depth = 300,
  theta_fc = 0.30,
  theta_wp = 0.15,
  depletion_factor = 0.55,
  irrigation_rule = "threshold"
)

print(head(wb_threshold$water_balance_data))
#> # A tibble: 6 × 13
#>     day rainfall   et0 root_depth   taw   raw depletion_start    kc    ks   etc
#>   <int>    <dbl> <dbl>      <dbl> <dbl> <dbl>           <dbl> <dbl> <dbl> <dbl>
#> 1     1        0   2.9        300    45  24.8            0      0.7     1  2.03
#> 2     2        0   4.4        300    45  24.8            2.03   0.7     1  3.08
#> 3     3        0   3.2        300    45  24.8            5.11   0.7     1  2.24
#> 4     4        0   4.6        300    45  24.8            7.35   0.7     1  3.22
#> 5     5        0   4.8        300    45  24.8           10.6    0.7     1  3.36
#> 6     6        0   2.1        300    45  24.8           13.9    0.7     1  1.47
#> # ℹ 3 more variables: depletion_end <dbl>, irrigation_applied <dbl>,
#> #   water_surplus <dbl>
print(wb_threshold$summary_depths)
#> $total_rainfall
#> [1] 104
#> 
#> $total_water_surplus
#> [1] 55.52
#> 
#> $net_rainfall
#> [1] 48.48
#> 
#> $total_etc
#> [1] 204.1825
#> 
#> $total_irrigation_applied
#> [1] 155.7025
#> 
#> $irrigation_events_count
#> [1] 6
#> 

# Fixed interval irrigation (every 7 days)
wb_fixed <- calc_water_balance(
  et0 = et0_data,
  rainfall = rain_data,
  daily_kc_values = kc_lettuce,
  root_depth = 300,
  theta_fc = 0.30,
  theta_wp = 0.15,
  depletion_factor = 0.55,
  irrigation_rule = 7
)

print(wb_fixed$summary_depths$irrigation_events_count)
#> [1] 8
```
