#' Flow unit conversion
#'
#' Helper function to convert flow rates between different units.
#'
#' @param q Flow rate value.
#' @param q_unit Flow measurement unit. Options are "m3/s", "l/h", "m3/h", or "l/s". Default is "m3/s".
#' @param operator Character indicating the operation: "div" to convert to m3/s, "mult" to convert from m3/s.
#'
#' @return Converted flow rate.
#' @keywords internal
#'
flow_unit <- function(q, q_unit = c("m3/s", "l/s", "m3/h", "l/h"), operator = c("div", "mult")) {
  # Validate and match arguments
  q_unit <- match.arg(q_unit)
  operator <- match.arg(operator)

  # Set conversion factor
  f <- switch(q_unit,
    "m3/s" = 1,
    "l/s"  = 1000,
    "m3/h" = 3600,
    "l/h"  = 3600000
  )

  # Apply conversion operation
  if (operator == "div") {
    return(q / f)
  } else {
    return(q * f)
  }
}
