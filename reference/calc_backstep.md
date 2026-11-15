# Calculate Pressure and Flow Profile Along a Lateral Line (Backstep Procedure)

Calculates the pressure head and flow rate profile along an irrigation
lateral line, starting from the distal end (last emitter) and stepping
backwards to the inlet using the Darcy-Weisbach equation via
[`hf::calc_head_loss_darcy()`](https://joaobtj.github.io/hf/reference/calc_head_loss_darcy.html).

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
  ...
)
```

## Arguments

- end_pressure:

  Numeric. Pressure head at the end of the lateral line (last emitter)
  in meters of water column (mca).

- diameter:

  Numeric. Internal pipe diameter in meters (m).

- spacing:

  Numeric vector or single value. Emitter spacing in meters (m).

- n_emitters:

  Integer. Total number of emitters on the lateral line (must be \>= 2).

- slope:

  Numeric. Elevation change (slope) per meter of pipe (m/m). Positive
  values indicate uphill slope, negative values indicate downhill slope.
  Defaults to `0`.

- emitter_coef:

  Numeric. Emitter discharge coefficient in SI units
  (\\\text{m}^3\\\text{s}^{-1}\\\text{mca}^{-x}\\).

- emitter_exp:

  Numeric. Emitter discharge exponent (between 0 and 1).

- ...:

  Additional arguments passed to
  [`hf::calc_head_loss_darcy()`](https://joaobtj.github.io/hf/reference/calc_head_loss_darcy.html)
  (such as `roughness`, `friction_factor`, or `viscosity`). Either
  `roughness` or `friction_factor` must be supplied.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the hydraulic profile of the lateral line:

- `emitter`: Integer emitter index (`1` is the first emitter near the
  inlet, `n` is the last).

- `pressure_head`: Pressure head at each emitter (mca).

- `emitter_flow`: Flow rate discharged by each emitter
  (\\\text{m}^3\\\text{s}^{-1}\\).

- `section_flow`: Flow rate in the pipe section immediately upstream of
  the emitter (\\\text{m}^3\\\text{s}^{-1}\\).

- `head_loss`: Friction head loss in the pipe section upstream of the
  emitter (m).

## Examples

``` r
# Lateral line with 5 emitters, 1 m spacing, and smooth PE roughness (1.5e-6 m)
calc_backstep(
  end_pressure = 10,
  diameter = 0.012,
  spacing = 1,
  n_emitters = 5,
  slope = 0,
  emitter_coef = 8.84e-7,
  emitter_exp = 0.50,
  roughness = 1.5e-6
)
#> # A tibble: 5 × 5
#>   emitter pressure_head emitter_flow section_flow head_loss
#>     <int>         <dbl>        <dbl>        <dbl>     <dbl>
#> 1       1          10.0   0.00000280   0.0000140   0.00225 
#> 2       2          10.0   0.00000280   0.0000112   0.00169 
#> 3       3          10.0   0.00000280   0.00000839  0.00112 
#> 4       4          10.0   0.00000280   0.00000559  0.000562
#> 5       5          10     0.00000280   0.00000280  0       

# Drip lateral line with 12 emitters and 0.3 m spacing
calc_backstep(
  end_pressure = 10,
  diameter = 0.012,
  spacing = 0.3,
  n_emitters = 12,
  slope = 0,
  emitter_coef = 3.18 / 3.6e6,
  emitter_exp = 0.50,
  roughness = 1.5e-6
)
#> # A tibble: 12 × 5
#>    emitter pressure_head emitter_flow section_flow head_loss
#>      <int>         <dbl>        <dbl>        <dbl>     <dbl>
#>  1       1          10.0   0.00000280   0.0000335   0.00401 
#>  2       2          10.0   0.00000280   0.0000307   0.00341 
#>  3       3          10.0   0.00000279   0.0000279   0.00285 
#>  4       4          10.0   0.00000279   0.0000251   0.00234 
#>  5       5          10.0   0.00000279   0.0000223   0.00187 
#>  6       6          10.0   0.00000279   0.0000196   0.00101 
#>  7       7          10.0   0.00000279   0.0000168   0.000843
#>  8       8          10.0   0.00000279   0.0000140   0.000674
#>  9       9          10.0   0.00000279   0.0000112   0.000506
#> 10      10          10.0   0.00000279   0.00000838  0.000337
#> 11      11          10.0   0.00000279   0.00000559  0.000169
#> 12      12          10     0.00000279   0.00000279  0       
```
