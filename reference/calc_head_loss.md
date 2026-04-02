# Calculate head loss in pipes by different methods

`calc_head_loss` calculates the friction head loss in pipes using
various methods commonly applied in agricultural hydraulics, including
Darcy-Weisbach (with multiple friction factor approximations),
Hazen-Williams, and Flamant.

## Usage

``` r
calc_head_loss(
  diameter,
  flow_rate,
  flow_unit = c("m3/s", "l/h", "m3/h", "l/s"),
  length,
  method = c("darcy_colebrook", "hazen_williams", "flamant", "swamee_jain", "blasius",
    "haaland", "churchill", "chen"),
  roughness = 1.5e-06,
  hazen_coef = 140,
  flamant_coef = 0.000135,
  viscosity = 1.01e-06,
  gravity = 9.81,
  initial_guess = 0.06
)
```

## Arguments

- diameter:

  Diameter of the pipe in meters (m).

- flow_rate:

  Flow rate value.

- flow_unit:

  Flow measurement unit. Options are "m3/s", "l/h", "m3/h", or "l/s".
  Default is "m3/s".

- length:

  Length of the pipe in meters (m).

- method:

  The method used to calculate head loss. Options are
  `"darcy_colebrook"` (default), `"hazen_williams"`, `"flamant"`,
  `"swamee_jain"`, `"blasius"`, `"haaland"`, `"churchill"`, and
  `"chen"`.

- roughness:

  Absolute roughness of the pipe in meters (m). Used for Darcy-Weisbach
  methods. Default is `1.5e-6` (typical for PVC and Polyethylene).

- hazen_coef:

  Hazen-Williams roughness coefficient (dimensionless). Default is 140
  (smooth plastic pipes).

- flamant_coef:

  Flamant roughness coefficient. Default is 0.000135 (plastic pipes).

- viscosity:

  Kinematic viscosity of the fluid in square meters per second (m^2/s).
  Default is the value for water at 20 degrees Celsius (`1.01e-6`).

- gravity:

  Gravitational acceleration in m/s^2. Default is 9.81.

- initial_guess:

  Initial parameter for the Newton-Raphson method (Colebrook). Default
  is 0.06.

## Value

A numeric value representing the friction head loss in meters (m).

## Details

**Reference values for Absolute Roughness in meters:**

- PVC and Polyethylene (PE): `1.5e-6` to `7.0e-6`

- Aluminum (with couplers): `1.5e-4` to `2.0e-4`

- Galvanized Steel: `1.5e-4`

- Cast Iron (new): `2.6e-4`

## References

- Blasius, H. (1913). Das Ähnlichkeitsgesetz bei Reibungsvorgängen in
  Flüssigkeiten. *Forschungsheft*, 131, 1-40.

- Bernardo, S., Soares, A. A., & Mantovani, E. C. (2019). *Manual de
  Irrigação* (9th ed.). Editora UFV.

- Chen, N. H. (1979). An explicit equation for friction factor in pipe.
  *Industrial & Engineering Chemistry Fundamentals*, 18(3), 296-297.

- Churchill, S. W. (1977). Friction-factor equation spans all fluid-flow
  regimes. *Chemical Engineering*, 84(24), 91-92.

- Colebrook, C. F. (1939). Turbulent flow in pipes... *Journal of the
  Institution of Civil Engineers*, 11(4), 133-156.

- Dunlop, E. J. (1991). *Wallingford software: The hydraulic friction of
  pipes*. Report SR 281.

- Haaland, S. E. (1983). Simple and explicit formulas for the friction
  factor... *Journal of Fluids Engineering*, 105(1), 89-90.

- Swamee, P. K., & Jain, A. K. (1976). Explicit equations for pipe-flow
  problems. *Journal of the Hydraulics Division*, 102(5), 657-664.

- Williams, G. S., & Hazen, A. (1905). *Hydraulic tables*. John Wiley &
  Sons.

## Examples

``` r
# Darcy-Weisbach with Colebrook-White (default)
calc_head_loss(diameter = 0.05, flow_rate = 10, flow_unit = "m3/h", length = 100)
#> [1] 3.985144

# Hazen-Williams for a PVC pipe
calc_head_loss(diameter = 0.05, flow_rate = 10, flow_unit = "m3/h", length = 100,
method = "hazen_williams")
#> [1] 4.521465
```
