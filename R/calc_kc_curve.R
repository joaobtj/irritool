#' Generate Crop Coefficient (Kc) Curve
#'
#' @description
#' Constructs a time series of daily crop coefficient (Kc) values and generates a `ggplot2`
#' visualization representing the Kc curve over the crop cycle, following FAO-56 guidelines.
#' The curve is divided into four stages: initial, development, mid-season, and late-season.
#'
#' @md
#' @param kc_points Numeric vector of length 3. Contains the crop coefficients
#' for the initial stage (`Kc_ini`), mid-season stage (`Kc_mid`), and end of the
#'  late-season stage (`Kc_end`).
#' @param stage_lengths Numeric vector of length 4. The duration (in days) of
#'  each growth stage: initial, development, mid-season, and late-season.
#' @param crop Character (optional). Name of the crop, used to customize the
#'  plot title.
#'
#' @return A list containing:
#' * `kc_serie`: A numeric vector of daily Kc values over the entire cycle.
#' * `kc_plot`: A `ggplot2` object displaying the constructed curve with key annotations.
#' * `kc_data`: A data frame containing the days and their corresponding Kc values.
#'
#' @references
#' Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop evapotranspiration - Guidelines for computing crop water requirements. FAO Irrigation and drainage paper 56.
#'
#' @export
#'
#' @import ggplot2
#' @importFrom scales pretty_breaks
#'
#' @examples
#' kc_points=kc_params_lettuce <- c(0.7, 1.0, 0.95) # Kc_ini, Kc_mid, Kc_end
#' stage_lengths=stage_lengths_lettuce <- c(15, 20, 20, 10) # L_ini, L_dev, L_mid, L_late
#' lettuce_data <- calc_kc_curve(
#'   kc_points = kc_params_lettuce,
#'   stage_lengths = stage_lengths_lettuce,
#'   crop = "Lettuce"
#' )
#' print(lettuce_data$kc_data)
#' print(lettuce_data$kc_plot)
#'
calc_kc_curve <- function(kc_points, stage_lengths, crop = NULL) {
  # --- Input Validation ---
  if (!is.numeric(kc_points) || length(kc_points) != 3) {
    stop("Argument 'kc_points' must be a numeric vector with 3 values (Kc_ini, Kc_mid, Kc_end).")
  }
  if (!is.numeric(stage_lengths) || length(stage_lengths) != 4) {
    stop("Argument 'stage_lengths' must be a numeric vector with 4 values (lengths of stages).")
  }
  if (any(stage_lengths < 0)) {
    stop("All stage lengths in 'stage_lengths' must be non-negative.")
  }
  if (any(!is.finite(kc_points)) || any(!is.finite(stage_lengths))) {
    stop("Kc values and stage lengths must be finite numbers.")
  }

  # Specific conditions based on FAO methodology for sloped phases
  # These ensure that if Kc values change, the phase has a duration.
  if (kc_points[1] == kc_points[2]) {
    stop("The value of Kc_ini and Kc_mid must be different for a development phase.")
  }
  if (kc_points[2] == kc_points[3]) {
    stop("The value of Kc_mid and Kc_end must be different for a late-season phase.")
  }

  # If Kc values are different, the corresponding development/late phase length must be > 0
  if (stage_lengths[2] == 0) { # Since kc_points[1] != kc_points[2] is guaranteed by the above check
    stop("Development phase length (stage_lengths[2]) must be greater than zero if Kc_ini and Kc_mid are different.")
  }
  if (stage_lengths[4] == 0) { # Since kc_points[2] != kc_points[3] is guaranteed by the above check
    stop("Late-season phase length (stage_lengths[4]) must be greater than zero if Kc_mid and Kc_end are different.")
  }

  # --- Kc Series Calculation ---
  # Stage 1: Initial stage
  kc_stage1 <- if (stage_lengths[1] > 0) rep(kc_points[1], stage_lengths[1]) else numeric(0)

  # Stage 2: Crop development stage (linear increase from Kc_ini to Kc_mid)
  # Kc_j = Kc_ini + (j / L_dev) * (Kc_mid - Kc_ini) for j = 1 to L_dev
  kc_stage2 <- if (stage_lengths[2] > 0) {
    kc_points[1] + (1:stage_lengths[2]) * (kc_points[2] - kc_points[1]) / stage_lengths[2]
  } else {
    numeric(0) # Should not be reached if stage_lengths[2]=0 due to prior stop()
  }

  # Stage 3: Mid-season stage
  kc_stage3 <- if (stage_lengths[3] > 0) rep(kc_points[2], stage_lengths[3]) else numeric(0)

  # Stage 4: Late-season stage (linear decrease/increase from Kc_mid to Kc_end)
  # Kc_j = Kc_mid + (j / L_late) * (Kc_end - Kc_mid) for j = 1 to L_late
  kc_stage4 <- if (stage_lengths[4] > 0) {
    kc_points[2] + (1:stage_lengths[4]) * (kc_points[3] - kc_points[2]) / stage_lengths[4]
  } else {
    numeric(0) # Should not be reached if stage_lengths[4]=0 due to prior stop()
  }

  kc_serie <- c(kc_stage1, kc_stage2, kc_stage3, kc_stage4)
  total_days <- sum(stage_lengths)

  if (length(kc_serie) == 0 && total_days > 0) {
    warning("Kc series is empty but total_days > 0. Check stage lengths if all are zero.")
    # This might happen if all stage_lengths are 0. sum(stage_lengths) = 0 in that case.
    # If total_days is sum(stage_lengths) and it's 0, kc_serie will be empty. This is fine.
  }
  if (length(kc_serie) != total_days) {
    # This would indicate an internal logic error if stage_lengths components are positive for changing Kcs
    stop("Internal error: Length of kc_serie does not match total_days. Please check stage_lengths values and Kc differences.")
  }


  # --- Plotting ---
  plot_data <- data.frame(
    day = seq_len(total_days),
    kc_value = kc_serie
  )

  # Determine sensible Y-axis limits for the plot
  min_kc_plot <- min(0, kc_serie, na.rm = TRUE)
  max_kc_plot <- max(1, kc_serie, na.rm = TRUE) # Ensure plot goes at least to 1 or max Kc

  # Define plot title
  plot_title <- if (!is.null(crop) && nzchar(crop)) {
    paste("Kc Curve for", crop)
  } else {
    "Crop Coefficient (Kc) Curve"
  }

  # Stage end-points for annotations and vertical lines
  day_end_ini <- stage_lengths[1]
  day_end_dev <- stage_lengths[1] + stage_lengths[2]
  day_end_mid <- stage_lengths[1] + stage_lengths[2] + stage_lengths[3]
  day_end_late <- total_days # same as stage_lengths[1] + stage_lengths[2] + stage_lengths[3] + stage_lengths[4]

  kc_plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = day, y = kc_value)) +
    ggplot2::geom_line(color = "steelblue", linewidth = 1) +
    ggplot2::scale_y_continuous(
      name = "Crop Coefficient (Kc)",
      limits = c(min_kc_plot, max_kc_plot * 1.05), # Add 5% padding to upper limit
      breaks = scales::pretty_breaks(n = 8) # More flexible breaks
    ) +
    ggplot2::scale_x_continuous(
      name = "Day of Crop Cycle",
      limits = c(0, total_days + max(5, total_days * 0.05)), # Pad x-axis
      breaks = scales::pretty_breaks(n = 10)
    ) +
    ggplot2::labs(title = plot_title, subtitle = paste("Total cycle length:", total_days, "days")) +
    ggplot2::theme_classic(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )

  # Annotate Kc values at key points, ensuring they are within plot limits
  # Annotate Kc_ini
  if (stage_lengths[1] >= 0) { # Kc_ini is always relevant
    kc_plot <- kc_plot +
      ggplot2::annotate("text",
        x = 0, y = kc_points[1],
        label = paste("Kc ini =", format(kc_points[1], digits = 2, nsmall = 2)),
        vjust = if (kc_points[1] < mean(plot_data$kc_value, na.rm = TRUE)) -0.5 else 1.5,
        hjust = 0, size = 3.5, color = "gray20"
      ) +
      ggplot2::annotate("point", x = 0, y = kc_points[1], color = "red", size = 2)
  }

  # Annotate Kc_mid (at the end of development stage)
  # This is also the Kc value for the mid-season stage
  if (stage_lengths[2] > 0) { # Only makes sense to specifically mark end of dev if dev stage exists
    kc_plot <- kc_plot +
      ggplot2::annotate("text",
        x = day_end_dev, y = kc_points[2],
        label = paste("Kc mid =", format(kc_points[2], digits = 2, nsmall = 2)),
        vjust = if (kc_points[2] > kc_points[1] && kc_points[2] > kc_points[3]) -0.5 else 1.5, # Adjust based on typical curve shape
        hjust = if (day_end_dev / total_days < 0.8) 0 else 1, # Adjust based on position
        size = 3.5, color = "gray20"
      ) +
      ggplot2::annotate("point", x = day_end_dev, y = kc_points[2], color = "red", size = 2)
  }


  # Annotate Kc_end (at the end of late season stage)
  if (stage_lengths[4] > 0) { # Only makes sense to specifically mark end of late if late stage exists
    kc_plot <- kc_plot +
      ggplot2::annotate("text",
        x = day_end_late, y = kc_points[3],
        label = paste("Kc end =", format(kc_points[3], digits = 2, nsmall = 2)),
        vjust = if (kc_points[3] < kc_points[2]) 1.5 else -0.5, # Adjust based on typical curve shape
        hjust = 1, size = 3.5, color = "gray20"
      ) +
      ggplot2::annotate("point", x = day_end_late, y = kc_points[3], color = "red", size = 2)
  }


  # Add vertical lines for stage divisions if they have positive length
  # and are not at the very beginning or very end of the total period
  if (stage_lengths[1] > 0 && day_end_ini < total_days) {
    kc_plot <- kc_plot + ggplot2::geom_vline(xintercept = day_end_ini, linetype = "dashed", color = "grey50")
  }
  if (stage_lengths[2] > 0 && day_end_dev < total_days) {
    kc_plot <- kc_plot + ggplot2::geom_vline(xintercept = day_end_dev, linetype = "dashed", color = "grey50")
  }
  if (stage_lengths[3] > 0 && day_end_mid < total_days) {
    kc_plot <- kc_plot + ggplot2::geom_vline(xintercept = day_end_mid, linetype = "dashed", color = "grey50")
  }


  return(
    list(
      kc_serie = kc_serie,
      kc_plot = kc_plot,
      kc_data = plot_data # Return the data frame used for plotting
    )
  )
}
