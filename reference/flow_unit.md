# Flow unit conversion

Helper function to convert flow rates between different units.

## Usage

``` r
flow_unit(
  flow_rate,
  flow_unit = c("m3/s", "l/h", "m3/h", "l/s"),
  operator = c("div", "mult")
)
```

## Arguments

- flow_rate:

  Flow rate value.

- flow_unit:

  Flow measurement unit. Options are "m3/s", "l/h", "m3/h", or "l/s".
  Default is "m3/s".

- operator:

  Character indicating the operation: "div" to convert to m3/s, "mult"
  to convert from m3/s.

## Value

Converted flow rate.
