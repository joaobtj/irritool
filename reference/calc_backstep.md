# Calculate Pressure and Flow Profile Along a Lateral Line (Backstep Procedure)

Calculates the pressure head and flow rate profile along an irrigation
lateral line, starting from the distal end (last emitter) and stepping
backwards to the inlet using one of the head loss equations from the
`hf` package: Darcy-Weisbach
([`hf::calc_head_loss_darcy()`](https://joaobtj.github.io/hf/reference/calc_head_loss_darcy.html)),
Flamant
([`hf::calc_head_loss_flamant()`](https://joaobtj.github.io/hf/reference/calc_head_loss_flamant.html)),
or Hazen-Williams
([`hf::calc_head_loss_hw()`](https://joaobtj.github.io/hf/reference/calc_head_loss_hw.html)).

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
  method = c("darcy", "flamant", "hw"),
  flow_unit = "m3/s",
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

  Numeric. Emitter discharge coefficient in units consistent with
  `flow_unit` (e.g., \\\text{m}^3\\\text{s}^{-1}\\\text{mca}^{-x}\\ when
  `flow_unit = "m3/s"`, or \\\text{L}\\\text{h}^{-1}\\\text{mca}^{-x}\\
  when `flow_unit = "L/h"`).

- emitter_exp:

  Numeric. Emitter discharge exponent (between 0 and 1).

- method:

  Character. Head loss equation to use: `"darcy"` for Darcy-Weisbach
  (default), `"flamant"` for Flamant, or `"hw"` for Hazen-Williams.

- flow_unit:

  Character. Unit of the volumetric flow rate used for `emitter_coef`
  and returned in `emitter_flow` and `section_flow`. Passed directly to
  the chosen `hf` head loss function. Options include `"m3/s"`
  (default), `"m3/min"`, `"m3/h"`, `"m3/d"`, `"L/s"`, `"L/min"`,
  `"L/h"`, and `"L/d"`.

- ...:

  Additional arguments passed to the chosen head loss function:

  - For `"darcy"`: `roughness`, `friction_factor`, `friction_fun`,
    `viscosity`, `gravity` (either `roughness` or `friction_factor` must
    be supplied).

  - For `"flamant"`: `coef` (default `0.000135`).

  - For `"hw"`: `coef` (default `140`).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
containing the hydraulic profile of the lateral line:

- `emitter`: Integer emitter index (`1` is the first emitter near the
  inlet, `n` is the last).

- `pressure_head`: Pressure head at each emitter (mca).

- `emitter_flow`: Flow rate discharged by each emitter (in `flow_unit`).

- `section_flow`: Flow rate in the pipe section immediately upstream of
  the emitter (in `flow_unit`).

- `head_loss`: Friction head loss in the pipe section upstream of the
  emitter (m).

## Examples

``` r
# 1. Darcy-Weisbach (default) with flow in m3/s
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

# 2. Drip lateral line using Flamant and flow in L/h
calc_backstep(
  end_pressure = 10,
  diameter = 0.012,
  spacing = 0.3,
  n_emitters = 12,
  slope = 0,
  emitter_coef = 3.18,
  emitter_exp = 0.50,
  method = "flamant",
  flow_unit = "L/h",
  coef = 0.000135
)
#> # A tibble: 12 × 5
#>    emitter pressure_head emitter_flow section_flow head_loss
#>      <int>         <dbl>        <dbl>        <dbl>     <dbl>
#>  1       1          10.0         10.1        121.  0.00417  
#>  2       2          10.0         10.1        111.  0.00353  
#>  3       3          10.0         10.1        101.  0.00294  
#>  4       4          10.0         10.1         90.5 0.00239  
#>  5       5          10.0         10.1         80.5 0.00189  
#>  6       6          10.0         10.1         70.4 0.00144  
#>  7       7          10.0         10.1         60.3 0.00105  
#>  8       8          10.0         10.1         50.3 0.000710 
#>  9       9          10.0         10.1         40.2 0.000429 
#> 10      10          10.0         10.1         30.2 0.000211 
#> 11      11          10.0         10.1         20.1 0.0000628
#> 12      12          10           10.1         10.1 0        

# 3. Hazen-Williams with custom C coefficient and flow in L/s
calc_backstep(
  end_pressure = 15,
  diameter = 0.025,
  spacing = 6,
  n_emitters = 8,
  slope = 0.02,
  emitter_coef = 0.05,
  emitter_exp = 0.50,
  method = "hw",
  flow_unit = "L/s",
  coef = 150
)
#> # A tibble: 8 × 5
#>   emitter pressure_head emitter_flow section_flow head_loss
#>     <int>         <dbl>        <dbl>        <dbl>     <dbl>
#> 1       1          21.7        0.233        1.66     2.02  
#> 2       2          19.5        0.221        1.42     1.48  
#> 3       3          17.9        0.212        1.20     1.03  
#> 4       4          16.8        0.205        0.990    0.672 
#> 5       5          16.0        0.200        0.785    0.390 
#> 6       6          15.5        0.197        0.585    0.183 
#> 7       7          15.2        0.195        0.388    0.0503
#> 8       8          15          0.194        0.194    0     
```
