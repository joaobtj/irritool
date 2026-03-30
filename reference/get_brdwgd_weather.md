# Extract Point Data from BR-DWGD

Extracts a daily time series of specified weather variables for a given
longitude and latitude from the Brazilian Daily Weather Gridded Data
(BR-DWGD) NetCDF files. The function identifies the closest grid cell to
the target coordinates.

## Usage

``` r
get_brdwgd_weather(
  target_longitude,
  target_latitude,
  weather_variables = c("pr", "Tmin", "Tmax", "Rs", "RH", "u2", "ETo"),
  date_range = NULL,
  nc_files_directory = "."
)
```

## Arguments

- target_longitude:

  Numeric. Longitude of the target location in decimal degrees.

- target_latitude:

  Numeric. Latitude of the target location in decimal degrees.

- weather_variables:

  Character vector. Variables to extract. Allowed values are: `"pr"`
  (precipitation), `"Tmin"`, `"Tmax"`, `"Rs"` (solar radiation), `"RH"`
  (relative humidity), `"u2"` (wind speed), and `"ETo"`. Defaults to
  all.

- date_range:

  Character vector of length 2 (`"YYYY-MM-DD"`). The start and end
  dates. If `NULL` (default), extracts the entire available period.

- nc_files_directory:

  Character. Path to the local directory containing the BR-DWGD NetCDF
  files. Defaults to current working directory `"."`.

## Value

A `tibble` containing the `date`, the actual `lat` and `lon` of the
closest grid cell, and columns for each requested weather variable.

## References

Xavier, A. C., King, C. W., & Scanlon, B. R. (2016). Daily gridded
meteorological variables in Brazil (1980–2013). International Journal of
Climatology.
<https://sites.google.com/site/alexandrecandidoxavierufes/brazilian-daily-weather-gridded-data>

## Examples

``` r
target_longitude = -50.5995
target_latitude = -27.2863
weather_variables = c("pr", "ETo", "Tmax")
date_range = c("1983-01-01", "1983-03-31")
nc_files_directory = "D:/clima_Xavier"


if (FALSE) { # \dontrun{
# Ensure the path to your NetCDF files is correct
weather_data_point <- get_brdwgd_weather(
  target_longitude = -50.5995,
  target_latitude = -27.2863,
  weather_variables = c("pr", "ETo", "Tmax"),
  date_range = c("1983-01-01", "1983-03-31"),
  nc_files_directory = "D:/clima_Xavier"
)
print(head(weather_data_point))
} # }
```
