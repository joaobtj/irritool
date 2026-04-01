#' Calculate head loss in pipes by different methods
#'
#' \code{calc_head_loss} calculates the friction head loss in pipes using various methods
#' commonly applied in agricultural hydraulics, including Darcy-Weisbach (with multiple
#' friction factor approximations), Hazen-Williams, and Flamant.
#'
#' @inheritParams flow_unit
#' @param d Diameter of the pipe in millimeters (mm).
#' @param l Length of the pipe in meters (m).
#' @param method The method used to calculate head loss. Options are \code{"darcy_colebrook"} (default),
#'   \code{"hazen_williams"}, \code{"flamant"}, \code{"swamee_jain"}, \code{"blasius"}, and \code{"haaland"}.
#' @param rc Absolute roughness of the pipe in meters (m). Used for Darcy-Weisbach methods.
#'   Default is \code{1.5e-6} (typical for PVC and Polyethylene).
#' @param hw_c Hazen-Williams roughness coefficient (dimensionless). Default is 140 (smooth plastic pipes).
#' @param flamant_b Flamant roughness coefficient. Default is 0.000135 (plastic pipes).
#' @param v Kinematic viscosity of the fluid in square meters per second (m^2/s).
#'   Default is the value for water at 20 degrees Celsius (\code{1.01e-6}).
#' @param g Gravitational acceleration in m/s^2. Default is 9.81.
#' @param x1 Initial parameter for the Newton-Raphson method (Colebrook). Default is 0.06.


#'
#' @details
#' \strong{Reference values for Absolute Roughness (rc) in meters:}
#' \itemize{
#'   \item PVC and Polyethylene (PE): \code{1.5e-6} to \code{7.0e-6}
#'   \item Aluminum (with couplers): \code{1.5e-4} to \code{2.0e-4}
#'   \item Galvanized Steel: \code{1.5e-4}
#'   \item Cast Iron (new): \code{2.6e-4}
#' }
#' @return A list containing:
#' \itemize{
#'   \item \code{hf}: Head loss in meters (m).
#'   \item \code{method}: The calculation method used.
#'   \item \code{regime}: Flow regime (only returned for Darcy-Weisbach methods).
#'   \item \code{f}: Darcy friction factor (only returned for Darcy-Weisbach methods).
#' }
#' @export
#'
#' @examples
#' # Darcy-Weisbach with Colebrook-White (default)
#' calc_head_loss(d = 50e-3, q = 10, q_unit = "m3/h", l = 100)
#'
#' # Hazen-Williams for a PVC pipe
#' calc_head_loss(d = 50e-3, q = 10, q_unit = "m3/h", l = 100, method = "hazen_williams")
#'
#' # Explicit Swamee-Jain approximation
#' calc_head_loss(d = 50e-3, q = 10, q_unit = "m3/h", l = 100, method = "swamee_jain")
calc_head_loss <- function(d, q, q_unit = c("m3/s", "l/h", "m3/h"), l,
                           method = c(
                             "darcy_colebrook", "hazen_williams", "flamant",
                             "swamee_jain", "blasius", "haaland"
                           ),
                           rc = 1.5e-6, hw_c = 140, flamant_b = 0.000135,
                           v = 1.01e-6, g = 9.81, x1 = 0.06) {
  # Validate arguments
  q_unit <- match.arg(q_unit)
  method <- match.arg(method)

  # Standardization of flow rate to m3/s using the internal helper function
  q_m3s <- flow_unit(q = q, q_unit = q_unit, operator = "div")

  # ---------------------------------------------------------------------------
  # Empirical Methods
  # ---------------------------------------------------------------------------

  if (method == "hazen_williams") {
    # Hazen-Williams equation (Metric)
    hf <- 10.67 * l * (q_m3s^1.852) / ((hw_c^1.852) * (d^4.87))
    return(hf = hf)
  } else if (method == "flamant") {
    # Flamant equation (Metric)
    hf <- (4 * flamant_b * l * (q_m3s^1.75)) / (d^4.75)
    return(hf = hf)
  }

  # ---------------------------------------------------------------------------
  # Darcy-Weisbach Based Methods
  # ---------------------------------------------------------------------------

  # Reynolds number
  re <- (4 * q_m3s) / (pi * d * v)

  # Universal Laminar Flow
  if (re < 2000) {
    regime <- "laminar"
    f <- 64 / re
  } else {
    regime <- if (re <= 4000) "transition" else "turbulent"

    # Select friction factor (f) approximation based on the method
    if (method == "darcy_colebrook") {
      if (re <= 4000) {
        # Transition: interpolation (Dunlop, 1991)
        y3 <- -0.86859 * log(rc / (3.7 * d) + 5.74 / 4000^0.9)
        y2 <- rc / (3.7 * d) + 5.74 / re^0.9
        fa <- y3^(-2)
        fb <- fa * (2 - 0.00514215 / (y2 * y3))
        r <- re / 2000

        x_val1 <- 7 * fa - fb
        x_val2 <- 0.128 - 17 * fa + 2.5 * fb
        x_val3 <- -0.128 + 13 * fa - 2 * fb
        x_val4 <- r * (0.032 - 3 * fa + 0.5 * fb)
        f <- (x_val1 + r * (x_val2 + r * (x_val3 + x_val4)))
      } else {
        # Turbulent: Colebrook-White via Newton-Raphson
        x_val <- (1 / x1)^0.5


        max_iter <- 1000
        iter <- 0

        repeat {
          iter <- iter + 1
          w <- (rc / (3.7 * d)) + ((2.51 * x_val) / re)
          h <- (2.18 / (((rc * re) / (3.7 * d)) + (2.51 * x_val)))
          x2 <- x_val - (((x_val + (2 * log10(w))) / (1 + h)))
          diff <- abs(x2 - x_val)
          x_val <- x2
          if (diff < 0.00001 || iter >= max_iter) break
        }
        f <- 1 / x_val^2
      }
    } else if (method == "swamee_jain") {
      # Swamee-Jain equation
      f <- 0.25 / (log10((rc / (3.7 * d)) + (5.74 / (re^0.9))))^2
    } else if (method == "blasius") {
      # Blasius equation (valid for smooth pipes)
      f <- 0.3164 / (re^0.25)
    } else if (method == "haaland") {
      # Haaland equation
      f <- 1 / (-1.8 * log10(((rc / (3.7 * d))^1.11) + (6.9 / re)))^2
    }
  }

  # Darcy-Weisbach equation for head loss
  hf <- (16 * f * q_m3s^2 * l) / (2 * g * pi^2 * d^5)

  return(hf = hf)
}
