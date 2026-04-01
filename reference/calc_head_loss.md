# Calculate head loss in pipes by different methods

`calc_head_loss` calculates the friction head loss in pipes using
various methods commonly applied in agricultural hydraulics, including
Darcy-Weisbach (with multiple friction factor approximations),
Hazen-Williams, and Flamant.

## Usage

``` r
calc_head_loss(
  d,
  q,
  q_unit = c("m3/s", "l/h", "m3/h"),
  l,
  method = c("darcy_colebrook", "hazen_williams", "flamant", "swamee_jain", "blasius",
    "haaland"),
  rc = 1.5e-06,
  hw_c = 140,
  flamant_b = 0.000135,
  v = 1.01e-06,
  g = 9.81,
  x1 = 0.06
)
```

## Arguments

- d:

  Diameter of the pipe in millimeters (mm).

- q:

  Flow rate value.

- q_unit:

  Flow measurement unit. Options are "m3/s", "l/h", "m3/h", or "l/s".
  Default is "m3/s".

- l:

  Length of the pipe in meters (m).

- method:

  The method used to calculate head loss. Options are
  `"darcy_colebrook"` (default), `"hazen_williams"`, `"flamant"`,
  `"swamee_jain"`, `"blasius"`, and `"haaland"`.

- rc:

  Absolute roughness of the pipe in meters (m). Used for Darcy-Weisbach
  methods. Default is `1.5e-6` (typical for PVC and Polyethylene).

- hw_c:

  Hazen-Williams roughness coefficient (dimensionless). Default is 140
  (smooth plastic pipes).

- flamant_b:

  Flamant roughness coefficient. Default is 0.000135 (plastic pipes).

- v:

  Kinematic viscosity of the fluid in square meters per second (m^2/s).
  Default is the value for water at 20 degrees Celsius (`1.01e-6`).

- g:

  Gravitational acceleration in m/s^2. Default is 9.81.

- x1:

  Initial parameter for the Newton-Raphson method (Colebrook). Default
  is 0.06.

## Value

A list containing:

- `hf`: Head loss in meters (m).

- `method`: The calculation method used.

- `regime`: Flow regime (only returned for Darcy-Weisbach methods).

- `f`: Darcy friction factor (only returned for Darcy-Weisbach methods).

## Details

**Reference values for Absolute Roughness (rc) in meters:**

- PVC and Polyethylene (PE): `1.5e-6` to `7.0e-6`

- Aluminum (with couplers): `1.5e-4` to `2.0e-4`

- Galvanized Steel: `1.5e-4`

- Cast Iron (new): `2.6e-4`

## Examples

``` r
# Darcy-Weisbach with Colebrook-White (default)
calc_head_loss(d = 50e-3, q = 10, q_unit = "m3/h", l = 100)
#> [1] 3.985144

# Hazen-Williams for a PVC pipe
calc_head_loss(d = 50e-3, q = 10, q_unit = "m3/h", l = 100, method = "hazen_williams")
#> [1] 4.521465

# Explicit Swamee-Jain approximation
calc_head_loss(d = 50e-3, q = 10, q_unit = "m3/h", l = 100, method = "swamee_jain")
#> [1] 3.961843
```
