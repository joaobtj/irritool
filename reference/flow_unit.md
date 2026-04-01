# Flow unit conversion

Helper function to convert flow rates between different units.

## Usage

``` r
flow_unit(
  q,
  q_unit = c("m3/s", "l/s", "m3/h", "l/h"),
  operator = c("div", "mult")
)
```

## Arguments

- q:

  Flow rate value.

- q_unit:

  Flow measurement unit. Options are "m3/s", "l/h", "m3/h", or "l/s".
  Default is "m3/s".

- operator:

  Character indicating the operation: "div" to convert to m3/s, "mult"
  to convert from m3/s.

## Value

Converted flow rate.
