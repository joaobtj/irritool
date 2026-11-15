#' Generate Crop Coefficient (Kc) Curve
#'
#' @description
#' Constructs a time series of daily crop coefficient (\eqn{K_c}) values and
#' generates a `ggplot2` visualization representing the \eqn{K_c} curve across the
#' crop cycle, following FAO-56 guidelines. The curve is divided into four
#' distinct stages: initial, development, mid-season, and late-season.
#'
#' @param kc_points Numeric vector of length 3 containing the crop coefficients
#'   for the initial stage (\eqn{K_{c\text{ ini}}}), mid-season stage (\eqn{K_{c\text{ mid}}}),
#'   and end of the late-season stage (\eqn{K_{c\text{ end}}}).
#' @param stage_lengths Numeric vector of length 4 containing the duration (in days)
#'   of each growth stage: initial (\eqn{L_{\text{ini}}}), development (\eqn{L_{\text{dev}}}),
#'   mid-season (\eqn{L_{\text{mid}}}), and late-season (\eqn{L_{\text{late}}}).
#' @param crop Character string (optional). Name of the crop, used to customize
#'   the plot title. Defaults to `NULL`.
#'
#' @return A named `list` containing:
#' * `kc_serie`: A numeric vector of daily \eqn{K_c} values over the entire cycle.
#' * `kc_plot`: A `ggplot2` object displaying the constructed curve and stage markers.
#' * `kc_data`: A [tibble::tibble()] containing the simulation days and corresponding \eqn{K_c} values.
#'
#' @references
#' Allen, R. G., Pereira, L. S., Raes, D., & Smith, M. (1998). Crop
#' evapotranspiration - Guidelines for computing crop water requirements. FAO
#' Irrigation and drainage paper 56. Food and Agriculture Organization of the
#' United Nations, Rome.
#'
#' @export
#'
#' @importFrom ggplot2 ggplot aes geom_line scale_y_continuous scale_x_continuous labs theme_classic theme element_text annotate geom_vline
#' @importFrom scales pretty_breaks
#' @importFrom rlang .data
#'
#' @examples
#' kc_params <- c(0.7, 1.0, 0.95)
#' stage_durations <- c(15, 20, 20, 10)
#' lettuce_kc <- calc_kc_curve(
#'   kc_points = kc_params,
#'   stage_lengths = stage_durations,
#'   crop = "Lettuce"
#' )
#'
#' print(lettuce_kc$kc_data)
#' print(lettuce_kc$kc_plot)
calc_kc_curve <- function(kc_points, stage_lengths, crop = NULL) {
  # --- Input Validation ---
  if (!is.numeric(kc_points) || length(kc_points) != 3L) {
    rlang::abort("`kc_points` must be a numeric vector of length 3: c(Kc_ini, Kc_mid, Kc_end).")
  }

  if (!is.numeric(stage_lengths) || length(stage_lengths) != 4L) {
    rlang::abort("`stage_lengths` must be a numeric vector of length 4: c(L_ini, L_dev, L_mid, L_late).")
  }

  if (any(stage_lengths < 0)) {
    rlang::abort("All stage lengths in `stage_lengths` must be non-negative.")
  }

  if (any(!is.finite(kc_points)) || any(!is.finite(stage_lengths))) {
    rlang::abort("Values in `kc_points` and `stage_lengths` must be finite numbers.")
  }

  if (kc_points[1] == kc_points[2]) {
    rlang::abort("`Kc_ini` and `Kc_mid` must be different for a crop development phase.")
  }

  if (kc_points[2] == kc_points[3]) {
    rlang::abort("`Kc_mid` and `Kc_end` must be different for a late-season phase.")
  }

  if (stage_lengths[2] == 0) {
    rlang::abort("Development phase duration (`stage_lengths[2]`) must be > 0 when Kc changes.")
  }

  if (stage_lengths[4] == 0) {
    rlang::abort("Late-season phase duration (`stage_lengths[4]`) must be > 0 when Kc changes.")
  }

  # --- Stage Calculations ---
  kc_stage1 <- if (stage_lengths[1] > 0) {
    rep(kc_points[1], stage_lengths[1])
  } else {
    numeric(0)
  }

  # Development phase: linear interpolation
  kc_stage2 <- kc_points[1] + (seq_len(stage_lengths[2])) * (kc_points[2] - kc_points[1]) / stage_lengths[2]

  kc_stage3 <- if (stage_lengths[3] > 0) {
    rep(kc_points[2], stage_lengths[3])
  } else {
    numeric(0)
  }

  # Late season phase: linear interpolation
  kc_stage4 <- kc_points[2] + (seq_len(stage_lengths[4])) * (kc_points[3] - kc_points[2]) / stage_lengths[4]

  kc_serie <- c(kc_stage1, kc_stage2, kc_stage3, kc_stage4)
  total_days <- sum(stage_lengths)

  if (length(kc_serie) != total_days) {
    rlang::abort("Internal error: Length of calculated `kc_serie` does not match `total_days`.")
  }

  plot_data <- tibble::tibble(
    day = seq_len(total_days),
    kc_value = kc_serie
  )

  # --- Visualization ---
  min_kc_plot <- min(0, kc_serie, na.rm = TRUE)
  max_kc_plot <- max(1, kc_serie, na.rm = TRUE)

  plot_title <- if (!is.null(crop) && nzchar(crop)) {
    paste("Kc Curve for", crop)
  } else {
    "Crop Coefficient (Kc) Curve"
  }

  day_end_ini <- stage_lengths[1]
  day_end_dev <- stage_lengths[1] + stage_lengths[2]
  day_end_mid <- stage_lengths[1] + stage_lengths[2] + stage_lengths[3]
  day_end_late <- total_days

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$day, y = .data$kc_value)) +
    ggplot2::geom_line(color = "steelblue", linewidth = 1) +
    ggplot2::scale_y_continuous(
      name = "Crop Coefficient (Kc)",
      limits = c(min_kc_plot, max_kc_plot * 1.05),
      breaks = scales::pretty_breaks(n = 8)
    ) +
    ggplot2::scale_x_continuous(
      name = "Day of Crop Cycle",
      limits = c(0, total_days + max(5, total_days * 0.05)),
      breaks = scales::pretty_breaks(n = 10)
    ) +
    ggplot2::labs(
      title = plot_title,
      subtitle = paste("Total cycle length:", total_days, "days")
    ) +
    ggplot2::theme_classic(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )

  # Annotate Kc_ini
  if (stage_lengths[1] >= 0) {
    p <- p +
      ggplot2::annotate(
        "text",
        x = 0,
        y = kc_points[1],
        label = paste("Kc ini =", format(kc_points[1], digits = 2, nsmall = 2)),
        vjust = if (kc_points[1] < mean(plot_data$kc_value, na.rm = TRUE)) -0.5 else 1.5,
        hjust = 0,
        size = 3.5,
        color = "gray20"
      ) +
      ggplot2::annotate("point", x = 0, y = kc_points[1], color = "red", size = 2)
  }

  # Annotate Kc_mid
  if (stage_lengths[2] > 0) {
    p <- p +
      ggplot2::annotate(
        "text",
        x = day_end_dev,
        y = kc_points[2],
        label = paste("Kc mid =", format(kc_points[2], digits = 2, nsmall = 2)),
        vjust = if (kc_points[2] > kc_points[1] && kc_points[2] > kc_points[3]) -0.5 else 1.5,
        hjust = if (day_end_dev / total_days < 0.8) 0 else 1,
        size = 3.5,
        color = "gray20"
      ) +
      ggplot2::annotate("point", x = day_end_dev, y = kc_points[2], color = "red", size = 2)
  }

  # Annotate Kc_end
  if (stage_lengths[4] > 0) {
    p <- p +
      ggplot2::annotate(
        "text",
        x = day_end_late,
        y = kc_points[3],
        label = paste("Kc end =", format(kc_points[3], digits = 2, nsmall = 2)),
        vjust = if (kc_points[3] < kc_points[2]) 1.5 else -0.5,
        hjust = 1,
        size = 3.5,
        color = "gray20"
      ) +
      ggplot2::annotate("point", x = day_end_late, y = kc_points[3], color = "red", size = 2)
  }

  # Vertical stage delimiters
  if (stage_lengths[1] > 0 && day_end_ini < total_days) {
    p <- p + ggplot2::geom_vline(xintercept = day_end_ini, linetype = "dashed", color = "grey50")
  }
  if (stage_lengths[2] > 0 && day_end_dev < total_days) {
    p <- p + ggplot2::geom_vline(xintercept = day_end_dev, linetype = "dashed", color = "grey50")
  }
  if (stage_lengths[3] > 0 && day_end_mid < total_days) {
    p <- p + ggplot2::geom_vline(xintercept = day_end_mid, linetype = "dashed", color = "grey50")
  }

  list(
    kc_serie = kc_serie,
    kc_plot = p,
    kc_data = plot_data
  )
}
