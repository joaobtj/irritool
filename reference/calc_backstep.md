# Calculate pressure and flow profile along a lateral line (Backstep procedure)

`calc_backstep` calculates the pressure head and flow rate profile along
an irrigation lateral line, starting from the distal end (last emitter)
and stepping backwards to the inlet.

## Usage

``` r
calc_backstep(
  end_pressure,
  diameter,
  spacing,
  n_emitters,
  slope = 0,
  emitter_coef,
  emitter_exp,
  flow_unit = c("m3/s", "l/h", "m3/h", "l/s"),
  ...
)
```

## Arguments

- end_pressure:

  Pressure head at the end of the lateral line (last emitter) in meters
  of water column (mca).

- diameter:

  Diameter of the pipe in meters (m).

- spacing:

  Emitter spacing in meters (m). Can be a single value or a vector of
  spacings.

- n_emitters:

  Total number of emitters on the lateral line.

- slope:

  Elevation change (slope) per meter of pipe (m/m). Positive values
  indicate uphill slope, negative for downhill.

- emitter_coef:

  Emitter discharge coefficient.

- emitter_exp:

  Emitter discharge exponent.

- flow_unit:

  Flow measurement unit. Options are "m3/s", "l/h", "m3/h", or "l/s".
  Default is "m3/s".

- ...:

  Additional arguments passed to
  [`calc_head_loss`](https://joaobtj.github.io/irritool/reference/calc_head_loss.md)
  (e.g., `method`, `roughness`, `hazen_coef`).

## Value

A data frame containing the profile of the lateral line:

- `emitter`: Emitter index (1 is the first emitter near the inlet, n is
  the last).

- `pressure_head`: Pressure head at each emitter (mca).

- `emitter_flow`: Flow rate discharged by each emitter.

- `section_flow`: Flow rate in the pipe section just upstream of the
  emitter.

- `head_loss`: Friction head loss in the pipe section upstream of the
  emitter (m).

## Examples

``` r
# Simple lateral line with 5 emitters, 1m spacing (returns flow in m3/s)
calc_backstep(
  end_pressure = 10, diameter = 0.012, spacing = 1, n_emitters = 5, slope = 0,
  emitter_coef = 8.84e-7, emitter_exp = 0.50
)
#>   emitter pressure_head emitter_flow section_flow    head_loss
#> 1       1      10.00566 2.796244e-06 1.397885e-05 0.0022621971
#> 2       2      10.00339 2.795928e-06 1.118260e-05 0.0016965918
#> 3       3      10.00170 2.795691e-06 8.386677e-06 0.0011310346
#> 4       4      10.00057 2.795532e-06 5.590986e-06 0.0005655093
#> 5       5      10.00000 2.795453e-06 2.795453e-06 0.0000000000

# Using Flamant method and returning flow in l/h (common for drip irrigation)
calc_backstep(
  end_pressure = 10, diameter = 0.012, spacing = 0.3, n_emitters = 12, slope = 0,
  emitter_coef = 3.18, emitter_exp = 0.50, flow_unit = "l/h", method = "flamant"
)
#>    emitter pressure_head emitter_flow section_flow    head_loss
#> 1        1      10.01233     10.06224    120.69472 2.733187e-03
#> 2        2      10.00960     10.06087    110.63247 2.313165e-03
#> 3        3      10.00729     10.05971    100.57161 1.923577e-03
#> 4        4      10.00536     10.05874     90.51190 1.565219e-03
#> 5        5      10.00380     10.05795     80.45316 1.239011e-03
#> 6        6      10.00256     10.05733     70.39521 9.460351e-04
#> 7        7      10.00161     10.05685     60.33788 6.875937e-04
#> 8        8      10.00093     10.05651     50.28102 4.653006e-04
#> 9        9      10.00046     10.05627     40.22451 2.812465e-04
#> 10      10      10.00018     10.05613     30.16824 1.383329e-04
#> 11      11      10.00004     10.05606     20.11211 4.112654e-05
#> 12      12      10.00000     10.05604     10.05604 0.000000e+00
```
