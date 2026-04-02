#' Calculate head loss in pipes by different methods
#'
#' \code{calc_head_loss} calculates the friction head loss in pipes using various methods
#' commonly applied in agricultural hydraulics, including Darcy-Weisbach (with multiple
#' friction factor approximations), Hazen-Williams, and Flamant.
#'
#' @inheritParams flow_unit
#' @param diameter Diameter of the pipe in meters (m).
#' @param length Length of the pipe in meters (m).
#' @param method The method used to calculate head loss. Options are \code{"darcy_colebrook"} (default),
#'   \code{"hazen_williams"}, \code{"flamant"}, \code{"swamee_jain"}, \code{"blasius"}, \code{"haaland"},
#'   \code{"churchill"}, and \code{"chen"}.
#' @param roughness Absolute roughness of the pipe in meters (m). Used for Darcy-Weisbach methods.
#'   Default is \code{1.5e-6} (typical for PVC and Polyethylene).
#' @param hazen_coef Hazen-Williams roughness coefficient (dimensionless). Default is 140 (smooth plastic pipes).
#' @param flamant_coef Flamant roughness coefficient. Default is 0.000135 (plastic pipes).
#' @param viscosity Kinematic viscosity of the fluid in square meters per second (m^2/s).
#'   Default is the value for water at 20 degrees Celsius (\code{1.01e-6}).
#' @param gravity Gravitational acceleration in m/s^2. Default is 9.81.
#' @param initial_guess Initial parameter for the Newton-Raphson method (Colebrook). Default is 0.06.
#'
#' @details
#' \strong{Reference values for Absolute Roughness in meters:}
#' \itemize{
#'   \item PVC and Polyethylene (PE): \code{1.5e-6} to \code{7.0e-6}
#'   \item Aluminum (with couplers): \code{1.5e-4} to \code{2.0e-4}
#'   \item Galvanized Steel: \code{1.5e-4}
#'   \item Cast Iron (new): \code{2.6e-4}
#' }
#'
#' @references
#' \itemize{
#'   \item Blasius, H. (1913). Das Ähnlichkeitsgesetz bei Reibungsvorgängen in Flüssigkeiten. \emph{Forschungsheft}, 131, 1-40.
#'   \item Bernardo, S., Soares, A. A., & Mantovani, E. C. (2019). \emph{Manual de Irrigação} (9th ed.). Editora UFV.
#'   \item Chen, N. H. (1979). An explicit equation for friction factor in pipe. \emph{Industrial & Engineering Chemistry Fundamentals}, 18(3), 296-297.
#'   \item Churchill, S. W. (1977). Friction-factor equation spans all fluid-flow regimes. \emph{Chemical Engineering}, 84(24), 91-92.
#'   \item Colebrook, C. F. (1939). Turbulent flow in pipes... \emph{Journal of the Institution of Civil Engineers}, 11(4), 133-156.
#'   \item Dunlop, E. J. (1991). \emph{Wallingford software: The hydraulic friction of pipes}. Report SR 281.
#'   \item Haaland, S. E. (1983). Simple and explicit formulas for the friction factor... \emph{Journal of Fluids Engineering}, 105(1), 89-90.
#'   \item Swamee, P. K., & Jain, A. K. (1976). Explicit equations for pipe-flow problems. \emph{Journal of the Hydraulics Division}, 102(5), 657-664.
#'   \item Williams, G. S., & Hazen, A. (1905). \emph{Hydraulic tables}. John Wiley & Sons.
#' }
#'
#' @return A numeric value representing the friction head loss in meters (m).
#' @export
#'
#' @examples
#' # Darcy-Weisbach with Colebrook-White (default)
#' calc_head_loss(diameter = 0.05, flow_rate = 10, flow_unit = "m3/h", length = 100)
#'
#' # Hazen-Williams for a PVC pipe
#' calc_head_loss(diameter = 0.05, flow_rate = 10, flow_unit = "m3/h", length = 100,
#' method = "hazen_williams")
calc_head_loss <- function(diameter, flow_rate, flow_unit = c("m3/s", "l/h", "m3/h", "l/s"), length,
                           method = c(
                             "darcy_colebrook", "hazen_williams", "flamant",
                             "swamee_jain", "blasius", "haaland", "churchill", "chen"
                           ),
                           roughness = 1.5e-6, hazen_coef = 140, flamant_coef = 0.000135,
                           viscosity = 1.01e-6, gravity = 9.81, initial_guess = 0.06) {
  # Validate arguments
  flow_unit <- match.arg(flow_unit)
  method <- match.arg(method)

  # Standardization of flow rate to m3/s using the internal helper function
  flow_rate_m3s <- flow_unit(flow_rate = flow_rate, flow_unit = flow_unit, operator = "div")

  # ---------------------------------------------------------------------------
  # Empirical Methods
  # ---------------------------------------------------------------------------

  if (method == "hazen_williams") {
    hf <- 10.67 * length * (flow_rate_m3s^1.852) / ((hazen_coef^1.852) * (diameter^4.87))
    return(hf)
  } else if (method == "flamant") {
    hf <- (4 * flamant_coef * length * (flow_rate_m3s^1.75)) / (diameter^4.75)
    return(hf)
  }

  # ---------------------------------------------------------------------------
  # Darcy-Weisbach Based Methods
  # ---------------------------------------------------------------------------

  # Reynolds number
  re <- (4 * flow_rate_m3s) / (pi * diameter * viscosity)

  # Universal Laminar Flow
  if (re < 2000) {
    f <- 64 / re
  } else {
    if (method == "darcy_colebrook") {
      if (re <= 4000) {
        # Transition: interpolation (Dunlop, 1991)
        y3 <- -0.86859 * log(roughness / (3.7 * diameter) + 5.74 / 4000^0.9)
        y2 <- roughness / (3.7 * diameter) + 5.74 / re^0.9
        fa <- y3^(-2)
        fb <- fa * (2 - 0.00514215 / (y2 * y3))
        r <- re / 2000

        x_val1 <- 7 * fa - fb
        x_val2 <- 0.128 - 17 * fa - 2.5 * fb # Corrigido sinal se for o caso, mantendo o padrão da literatura
        x_val2 <- 0.128 - 17 * fa + 2.5 * fb
        x_val3 <- -0.128 + 13 * fa - 2 * fb
        x_val4 <- r * (0.032 - 3 * fa + 0.5 * fb)
        f <- (x_val1 + r * (x_val2 + r * (x_val3 + x_val4)))
      } else {
        # Turbulent: Colebrook-White via Newton-Raphson
        x_val <- (1 / initial_guess)^0.5
        max_iter <- 1000
        iter <- 0

        repeat {
          iter <- iter + 1
          w <- (roughness / (3.7 * diameter)) + ((2.51 * x_val) / re)
          h <- (2.18 / (((roughness * re) / (3.7 * diameter)) + (2.51 * x_val)))
          x2 <- x_val - (((x_val + (2 * log10(w))) / (1 + h)))
          diff <- abs(x2 - x_val)
          x_val <- x2
          if (diff < 0.00001 || iter >= max_iter) break
        }
        f <- 1 / x_val^2
      }
    } else if (method == "swamee_jain") {
      f <- 0.25 / (log10((roughness / (3.7 * diameter)) + (5.74 / (re^0.9))))^2
    } else if (method == "blasius") {
      f <- 0.3164 / (re^0.25)
    } else if (method == "haaland") {
      f <- 1 / (-1.8 * log10(((roughness / (3.7 * diameter))^1.11) + (6.9 / re)))^2
    } else if (method == "churchill") {
      A <- (-2.457 * log((7 / re)^0.9 + 0.27 * (roughness / diameter)))^16
      B <- (37530 / re)^16
      f <- 8 * ((8 / re)^12 + 1 / (A + B)^1.5)^(1 / 12)
    } else if (method == "chen") {
      termo_interno <- (1 / 2.8257) * (roughness / diameter)^1.1098 + (5.8506 / re^0.8981)
      f <- 1 / (-2.0 * log10((roughness / (3.7065 * diameter)) - (5.0452 / re) * log10(termo_interno)))^2
    }
  }

  hf <- (16 * f * flow_rate_m3s^2 * length) / (2 * gravity * pi^2 * diameter^5)

  return(hf)
}
