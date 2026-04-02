#' Calculate pressure and flow profile along a lateral line (Backstep procedure)
#'
#' \code{calc_backstep} calculates the pressure head and flow rate profile along
#' an irrigation lateral line, starting from the distal end (last emitter) and
#' stepping backwards to the inlet.
#'
#' @inheritParams calc_head_loss
#' @param end_pressure Pressure head at the end of the lateral line (last emitter) in meters of water column (mca).
#' @param spacing Emitter spacing in meters (m). Can be a single value or a vector of spacings.
#' @param n_emitters Total number of emitters on the lateral line.
#' @param slope Elevation change (slope) per meter of pipe (m/m). Positive values indicate uphill slope, negative for downhill.
#' @param emitter_coef Emitter discharge coefficient.
#' @param emitter_exp Emitter discharge exponent.
#' @param ... Additional arguments passed to \code{\link{calc_head_loss}} (e.g., \code{method}, \code{roughness}, \code{hazen_coef}).
#'
#' @return A data frame containing the profile of the lateral line:
#' \itemize{
#'   \item \code{emitter}: Emitter index (1 is the first emitter near the inlet, n is the last).
#'   \item \code{pressure_head}: Pressure head at each emitter (mca).
#'   \item \code{emitter_flow}: Flow rate discharged by each emitter.
#'   \item \code{section_flow}: Flow rate in the pipe section just upstream of the emitter.
#'   \item \code{head_loss}: Friction head loss in the pipe section upstream of the emitter (m).
#' }
#' @export
#'
#' @examples
#' # Simple lateral line with 5 emitters, 1m spacing (returns flow in m3/s)
#' calc_backstep(
#'   end_pressure = 10, diameter = 0.012, spacing = 1, n_emitters = 5, slope = 0,
#'   emitter_coef = 8.84e-7, emitter_exp = 0.50
#' )
#'
#' # Using Flamant method and returning flow in l/h (common for drip irrigation)
#' calc_backstep(
#'   end_pressure = 10, diameter = 0.012, spacing = 0.3, n_emitters = 12, slope = 0,
#'   emitter_coef = 3.18, emitter_exp = 0.50, flow_unit = "l/h", method = "flamant"
#' )
calc_backstep <- function(end_pressure, diameter, spacing, n_emitters, slope = 0, emitter_coef, emitter_exp,
                          flow_unit = c("m3/s", "l/h", "m3/h", "l/s"), ...) {
  # Validations
  if (n_emitters < 2) stop("The parameter 'n_emitters' must be 2 or more.")
  if (emitter_exp >= 1 || emitter_exp < 0) stop("The parameter 'emitter_exp' must be between 0 and 1.")

  flow_unit <- match.arg(flow_unit)

  # Convert the emission coefficient flow base to m3/s for internal calculations
  emitter_coef_m3s <- flow_unit(flow_rate = emitter_coef, flow_unit = flow_unit, operator = "div")

  # Expand spacing vector to find the distance between each emitter
  if (n_emitters %% length(spacing) != 0 && length(spacing) != 1) {
    stop("The parameter 'n_emitters' must be a multiple of the 'spacing' vector length.")
  }
  se <- utils::head(rep(spacing, length.out = n_emitters), -1)

  # Initialize vectors for the data frame
  h_em <- numeric(n_emitters)
  q_em <- numeric(n_emitters)
  q_sec <- numeric(n_emitters)
  hf <- numeric(n_emitters)

  # Last emitter - The starting point of the backstep
  h_em[n_emitters] <- end_pressure
  q_em[n_emitters] <- emitter_coef_m3s * (h_em[n_emitters]^emitter_exp)
  q_sec[n_emitters] <- q_em[n_emitters]
  hf[n_emitters] <- 0

  # Loop (Backstep from n_emitters down to 2)
  for (i in n_emitters:2) {
    # Calculate head loss in the section upstream of emitter i
    loss <- calc_head_loss(diameter = diameter, flow_rate = q_sec[i], flow_unit = "m3/s", length = se[i - 1], ...)
    hf[i - 1] <- loss

    # Calculate pressure at upstream emitter
    h_em[i - 1] <- h_em[i] + (slope * se[i - 1]) + hf[i - 1]

    # Calculate flow of upstream emitter
    q_em[i - 1] <- emitter_coef_m3s * (h_em[i - 1]^emitter_exp)

    # Flow in the upstream section
    q_sec[i - 1] <- q_sec[i] + q_em[i - 1]
  }

  # Convert flows back to the requested user unit for output
  q_em_out <- flow_unit(flow_rate = q_em, flow_unit = flow_unit, operator = "mult")
  q_sec_out <- flow_unit(flow_rate = q_sec, flow_unit = flow_unit, operator = "mult")

  # Return as a structured data frame with descriptive column names
  res <- data.frame(
    emitter       = 1:n_emitters,
    pressure_head = h_em,
    emitter_flow  = q_em_out,
    section_flow  = q_sec_out,
    head_loss     = hf
  )

  return(res)
}
