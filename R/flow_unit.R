#' Flow unit conversion
#'
#' Helper function to convert flow rates between different units.
#'
#' @param flow_rate Flow rate value.
#' @param flow_unit Flow measurement unit. Options are "m3/s", "l/h", "m3/h", or "l/s". Default is "m3/s".
#' @param operator Character indicating the operation: "div" to convert to m3/s, "mult" to convert from m3/s.
#'
#' @return Converted flow rate.
#' @keywords internal
flow_unit <- function(flow_rate, flow_unit = c("m3/s", "l/h", "m3/h", "l/s"), operator = c("div", "mult")) {
  # Validate and match arguments
  flow_unit <- match.arg(flow_unit)
  operator <- match.arg(operator)

  # Set conversion factor
  f <- switch(flow_unit,
    "m3/s" = 1,
    "l/h"  = 3600000,
    "m3/h" = 3600,
    "l/s"  = 1000
  )

  # Apply conversion operation
  if (operator == "div") {
    return(flow_rate / f)
  } else {
    return(flow_rate * f)
  }
}
