#' @title Calculate Pressure and Flow Profile Along a Lateral Line (Backstep Procedure)
#'
#' @description
#' Calculates the pressure head and flow rate profile along an irrigation lateral
#' line, starting from the distal end (last emitter) and stepping backwards to
#' the inlet using one of the head loss equations from the `hf` package:
#' Darcy-Weisbach ([hf::calc_head_loss_darcy()]), Flamant
#' ([hf::calc_head_loss_flamant()]), or Hazen-Williams ([hf::calc_head_loss_hw()]).
#'
#' @param end_pressure Numeric. Pressure head at the end of the lateral line
#'   (last emitter) in meters of water column (mca).
#' @param diameter Numeric. Internal pipe diameter in meters (m).
#' @param spacing Numeric vector or single value. Emitter spacing in meters (m).
#' @param n_emitters Integer. Total number of emitters on the lateral line (must be >= 2).
#' @param slope Numeric. Elevation change (slope) per meter of pipe (m/m). Positive
#'   values indicate uphill slope, negative values indicate downhill slope. Defaults to `0`.
#' @param emitter_coef Numeric. Emitter discharge coefficient in units consistent with
#'   `flow_unit` (e.g., \eqn{\text{m}^3\,\text{s}^{-1}\,\text{mca}^{-x}} when
#'   `flow_unit = "m3/s"`, or \eqn{\text{L}\,\text{h}^{-1}\,\text{mca}^{-x}} when
#'   `flow_unit = "L/h"`).
#' @param emitter_exp Numeric. Emitter discharge exponent (between 0 and 1).
#' @param method Character. Head loss equation to use: `"darcy"` for Darcy-Weisbach
#'   (default), `"flamant"` for Flamant, or `"hw"` for Hazen-Williams.
#' @param flow_unit Character. Unit of the volumetric flow rate used for `emitter_coef`
#'   and returned in `emitter_flow` and `section_flow`. Passed directly to the chosen
#'   `hf` head loss function. Options include `"m3/s"` (default), `"m3/min"`, `"m3/h"`,
#'   `"m3/d"`, `"L/s"`, `"L/min"`, `"L/h"`, and `"L/d"`.
#' @param ... Additional arguments passed to the chosen head loss function:
#'   * For `"darcy"`: `roughness`, `friction_factor`, `friction_fun`, `viscosity`, `gravity`
#'     (either `roughness` or `friction_factor` must be supplied).
#'   * For `"flamant"`: `coef` (default `0.000135`).
#'   * For `"hw"`: `coef` (default `140`).
#'
#' @return A [tibble::tibble()] containing the hydraulic profile of the lateral line:
#' * `emitter`: Integer emitter index (`1` is the first emitter near the inlet, `n` is the last).
#' * `pressure_head`: Pressure head at each emitter (mca).
#' * `emitter_flow`: Flow rate discharged by each emitter (in `flow_unit`).
#' * `section_flow`: Flow rate in the pipe section immediately upstream of the emitter (in `flow_unit`).
#' * `head_loss`: Friction head loss in the pipe section upstream of the emitter (m).
#'
#' @importFrom rlang abort
#' @importFrom tibble tibble
#' @importFrom utils head
#' @importFrom hf calc_head_loss_darcy calc_head_loss_flamant calc_head_loss_hw
#'
#' @export
#'
#' @examples
#' # 1. Darcy-Weisbach (default) with flow in m3/s
#' calc_backstep(
#'   end_pressure = 10,
#'   diameter = 0.012,
#'   spacing = 1,
#'   n_emitters = 5,
#'   slope = 0,
#'   emitter_coef = 8.84e-7,
#'   emitter_exp = 0.50,
#'   roughness = 1.5e-6
#' )
#'
#' # 2. Drip lateral line using Flamant and flow in L/h
#' calc_backstep(
#'   end_pressure = 10,
#'   diameter = 0.012,
#'   spacing = 0.3,
#'   n_emitters = 12,
#'   slope = 0,
#'   emitter_coef = 3.18,
#'   emitter_exp = 0.50,
#'   method = "flamant",
#'   flow_unit = "L/h",
#'   coef = 0.000135
#' )
#'
#' # 3. Hazen-Williams with custom C coefficient and flow in L/s
#' calc_backstep(
#'   end_pressure = 15,
#'   diameter = 0.025,
#'   spacing = 6,
#'   n_emitters = 8,
#'   slope = 0.02,
#'   emitter_coef = 0.05,
#'   emitter_exp = 0.50,
#'   method = "hw",
#'   flow_unit = "L/s",
#'   coef = 150
#' )
calc_backstep <- function(end_pressure,
                          diameter,
                          spacing,
                          n_emitters,
                          slope = 0,
                          emitter_coef,
                          emitter_exp,
                          method = c("darcy", "flamant", "hw"),
                          flow_unit = "m3/s",
                          ...) {
  method <- match.arg(method)

  if (!is.numeric(n_emitters) || length(n_emitters) != 1L || n_emitters < 2 || n_emitters %% 1 != 0) {
    abort("`n_emitters` must be a single integer greater than or equal to 2.")
  }

  if (!is.numeric(emitter_exp) || length(emitter_exp) != 1L || emitter_exp >= 1 || emitter_exp < 0) {
    abort("`emitter_exp` must be a single numeric value in [0, 1).")
  }

  if (!is.numeric(end_pressure) || length(end_pressure) != 1L || end_pressure <= 0) {
    abort("`end_pressure` must be a single positive numeric value.")
  }

  if (!is.numeric(diameter) || length(diameter) != 1L || diameter <= 0) {
    abort("`diameter` must be a single positive numeric value.")
  }

  if (!is.numeric(spacing) || any(spacing <= 0)) {
    abort("`spacing` must contain positive numeric values.")
  }

  if (n_emitters %% length(spacing) != 0 && length(spacing) != 1L) {
    abort("`n_emitters` must be a multiple of the `spacing` vector length.")
  }

  loss_fun <- switch(
    method,
    darcy = calc_head_loss_darcy,
    flamant = calc_head_loss_flamant,
    hw = calc_head_loss_hw
  )

  se <- head(rep(spacing, length.out = n_emitters), -1L)

  h_em <- numeric(n_emitters)
  q_em <- numeric(n_emitters)
  q_sec <- numeric(n_emitters)
  hf <- numeric(n_emitters)

  # Boundary condition at the distal emitter
  h_em[n_emitters] <- end_pressure
  q_em[n_emitters] <- emitter_coef * (h_em[n_emitters]^emitter_exp)
  q_sec[n_emitters] <- q_em[n_emitters]
  hf[n_emitters] <- 0

  # Step backwards from last emitter to inlet
  for (i in n_emitters:2) {
    loss <- loss_fun(
      diameter = diameter,
      flow = q_sec[i],
      length = se[i - 1L],
      flow_unit = flow_unit,
      ...
    )
    hf[i - 1L] <- loss
    h_em[i - 1L] <- h_em[i] + (slope * se[i - 1L]) + hf[i - 1L]
    q_em[i - 1L] <- emitter_coef * (h_em[i - 1L]^emitter_exp)
    q_sec[i - 1L] <- q_sec[i] + q_em[i - 1L]
  }

  tibble(
    emitter = seq_len(n_emitters),
    pressure_head = h_em,
    emitter_flow = q_em,
    section_flow = q_sec,
    head_loss = hf
  )
}
