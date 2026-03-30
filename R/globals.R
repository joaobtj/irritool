# Declare column variables used in dplyr and ggplot2
# to avoid NOTEs during R CMD check
utils::globalVariables(c(
  "day",
  "kc_value",
  "lat_idx",
  "lon_idx",
  "nc_lon",
  "nc_lat",
  "distance"
))
