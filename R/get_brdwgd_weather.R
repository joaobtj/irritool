#' Extract Point Data from BR-DWGD
#'
#' @description
#' Extracts a daily time series of specified weather variables for a given longitude and latitude
#' from the Brazilian Daily Weather Gridded Data (BR-DWGD) NetCDF files. The function identifies
#' the closest grid cell to the target coordinates.
#'
#' @md
#' @param target_longitude Numeric. Longitude of the target location in decimal degrees.
#' @param target_latitude Numeric. Latitude of the target location in decimal degrees.
#' @param weather_variables Character vector. Variables to extract. Allowed values are: `"pr"` (precipitation), `"Tmin"`, `"Tmax"`, `"Rs"` (solar radiation), `"RH"` (relative humidity), `"u2"` (wind speed), and `"ETo"`. Defaults to all.
#' @param date_range Character vector of length 2 (`"YYYY-MM-DD"`). The start and end dates. If `NULL` (default), extracts the entire available period.
#' @param nc_files_directory Character. Path to the local directory containing the BR-DWGD NetCDF files. Defaults to current working directory `"."`.
#'
#' @return A `tibble` containing the `date`, the actual `lat` and `lon` of the closest grid cell, and columns for each requested weather variable.
#'
#' @references
#' Xavier, A. C., King, C. W., & Scanlon, B. R. (2016). Daily gridded meteorological variables in Brazil (1980–2013). International Journal of Climatology. \url{https://sites.google.com/site/alexandrecandidoxavierufes/brazilian-daily-weather-gridded-data}
#'
#'
#' @import dplyr
#' @import ncdf4
#' @importFrom rlang :=
#' @importFrom stringr word
#' @importFrom tibble tibble
#' @importFrom purrr reduce
#'
#' @export
#'
#' @examples
#' target_longitude <- -50.5995
#' target_latitude <- -27.2863
#' weather_variables <- c("pr", "ETo", "Tmax")
#' date_range <- c("1983-01-01", "1983-03-31")
#' nc_files_directory <- "D:/clima_Xavier"
#'
#' \dontrun{
#' # Ensure the path to your NetCDF files is correct
#' weather_data_point <- get_brdwgd_weather(
#'   target_longitude = -50.5995,
#'   target_latitude = -27.2863,
#'   weather_variables = c("pr", "ETo", "Tmax"),
#'   date_range = c("1983-01-01", "1983-03-31"),
#'   nc_files_directory = "D:/clima_Xavier"
#' )
#' print(head(weather_data_point))
#' }
get_brdwgd_weather <- function(target_longitude,
                               target_latitude,
                               weather_variables = c("pr", "Tmin", "Tmax", "Rs", "RH", "u2", "ETo"),
                               date_range = NULL,
                               nc_files_directory = ".") {
  # --- Validate Inputs ---
  if (!is.numeric(target_longitude) || length(target_longitude) != 1) {
    stop("'target_longitude' must be a single numeric value.")
  }
  if (!is.numeric(target_latitude) || length(target_latitude) != 1) {
    stop("'target_latitude' must be a single numeric value.")
  }
  # Basic check for Brazil's approximate bounds (can be refined)
  if (target_longitude > -34 || target_longitude < -74 || target_latitude > 5.5 || target_latitude < -34) {
    warning("Target coordinates are outside the typical bounds of Brazil. Ensure they are correct.")
  }

  allowed_vars <- c("pr", "Tmin", "Tmax", "Rs", "RH", "u2", "ETo")
  if (!all(weather_variables %in% allowed_vars)) {
    invalid_vars <- weather_variables[!weather_variables %in% allowed_vars]
    stop(paste(
      "Invalid weather variable(s):", paste(invalid_vars, collapse = ", "),
      ". Allowed variables are:", paste(allowed_vars, collapse = ", ")
    ))
  }

  if (!dir.exists(nc_files_directory)) {
    stop(paste("NetCDF directory not found:", nc_files_directory))
  }

  # Handle date_range
  if (is.null(date_range)) {
    # Full documented period for BR-DWGD
    date_range_processed <- as.Date(c("1961-01-01", "2020-06-30"))
    message("No 'date_range' provided. Using full available period: 1961-01-01 to 2020-06-30.")
  } else {
    if (length(date_range) != 2) stop("'date_range' must be a character vector of two dates (start and end).")
    date_range_processed <- tryCatch(as.Date(date_range), error = function(e) NULL)
    if (is.null(date_range_processed) || any(is.na(date_range_processed))) {
      stop("'date_range' could not be converted to Dates. Please use 'YYYY-MM-DD' format.")
    }
    if (date_range_processed[1] > date_range_processed[2]) {
      stop("Error: Start date in 'date_range' cannot be after the end date.")
    }
  }
  start_date_requested <- date_range_processed[1]
  end_date_requested <- date_range_processed[2]

  all_variables_data_list <- list()

  # Loop through each requested weather variable
  for (i in seq_along(weather_variables)) {
    current_variable_name <- weather_variables[i]

    # Construct regex pattern to find relevant NetCDF files for the current variable
    # Assumes files are named like: [variable]_*.nc (e.g., pr_1961_1970_BRDWGD.nc)
    nc_file_pattern <- paste0("^", current_variable_name, "_.*\\.nc$")
    variable_nc_files <- list.files(
      path = nc_files_directory,
      pattern = nc_file_pattern,
      full.names = TRUE
    ) # Get full paths

    if (length(variable_nc_files) == 0) {
      warning(paste(
        "No NetCDF files found for variable '", current_variable_name,
        "' in directory '", nc_files_directory, "' with pattern '", nc_file_pattern, "'. Skipping this variable."
      ))
      next # Skip to the next variable
    }

    data_from_files_list <- list()
    # Loop through all NetCDF files found for the current variable (e.g., pr_1961-1970.nc, pr_1971-1980.nc)
    for (j in seq_along(variable_nc_files)) {
      nc_file_path <- variable_nc_files[j]
      nc_file_obj <- tryCatch(ncdf4::nc_open(nc_file_path), error = function(e) {
        warning(paste("Could not open NetCDF file:", nc_file_path, "-", e$message))
        NULL
      })

      if (is.null(nc_file_obj)) next # Skip if file couldn't be opened

      # Extract latitude, longitude, and time dimensions from the NetCDF file
      nc_latitudes <- tryCatch(ncdf4::ncvar_get(nc_file_obj, varid = "latitude"), error = function(e) NULL)
      nc_longitudes <- tryCatch(ncdf4::ncvar_get(nc_file_obj, varid = "longitude"), error = function(e) NULL)
      nc_time_raw <- tryCatch(ncdf4::ncvar_get(nc_file_obj, varid = "time"), error = function(e) NULL)

      if (is.null(nc_latitudes) || is.null(nc_longitudes) || is.null(nc_time_raw)) {
        warning(paste("Could not read lat, lon, or time from:", nc_file_path, ". Skipping this file."))
        ncdf4::nc_close(nc_file_obj)
        next
      }

      # Convert NetCDF time (often hours since an origin) to Date objects
      time_units_string <- ncdf4::ncatt_get(nc_file_obj, "time")$units
      # Expected format "hours since YYYY-MM-DD" or "days since YYYY-MM-DD" etc.
      time_origin_date <- as.Date(stringr::word(time_units_string, 3)) # Get the last word as date
      time_unit <- stringr::word(time_units_string, 1) # Get the unit (hours, days)

      if (tolower(time_unit) == "hours") {
        nc_timestamps <- as.Date(nc_time_raw / 24, origin = time_origin_date)
      } else if (tolower(time_unit) == "days") {
        nc_timestamps <- as.Date(nc_time_raw, origin = time_origin_date)
      } else {
        warning(paste("Unsupported time unit '", time_unit, "' in file: ", nc_file_path, ". Skipping this file."))
        ncdf4::nc_close(nc_file_obj)
        next
      }

      # Find the grid point closest to the target coordinates
      # Uses Cartesian distance on degrees (a common simplification for nearest grid cell)
      closest_point_info <- expand.grid(lat_idx = seq_along(nc_latitudes), lon_idx = seq_along(nc_longitudes)) |>
        dplyr::mutate(
          nc_lat = nc_latitudes[lat_idx],
          nc_lon = nc_longitudes[lon_idx],
          distance = sqrt((nc_lon - target_longitude)^2 + (nc_lat - target_latitude)^2)
        ) |>
        dplyr::slice_min(distance, n = 1, with_ties = FALSE) # Get the single closest point

      # Determine time indices within the current file that overlap with the requested date_range
      # Read data for the intersection of requested range and file's range
      file_start_date <- min(nc_timestamps, na.rm = TRUE)
      file_end_date <- max(nc_timestamps, na.rm = TRUE)

      actual_read_start_date <- max(start_date_requested, file_start_date)
      actual_read_end_date <- min(end_date_requested, file_end_date)

      if (actual_read_start_date > actual_read_end_date) { # No overlap
        ncdf4::nc_close(nc_file_obj)
        next
      }

      start_time_index_in_file <- which.min(abs(nc_timestamps - actual_read_start_date))
      end_time_index_in_file <- which.min(abs(nc_timestamps - actual_read_end_date))

      # Ensure indices are monotonic if multiple dates are identical to target
      if (length(start_time_index_in_file) > 1) start_time_index_in_file <- min(start_time_index_in_file)
      if (length(end_time_index_in_file) > 1) end_time_index_in_file <- max(end_time_index_in_file)


      if (is.na(start_time_index_in_file) || is.na(end_time_index_in_file) || start_time_index_in_file > end_time_index_in_file) {
        ncdf4::nc_close(nc_file_obj)
        next # No valid time slice in this file for the request
      }

      # Define the starting indices and count for ncvar_get
      # (lon_index, lat_index, time_index)
      start_indices <- c(closest_point_info$lon_idx, closest_point_info$lat_idx, start_time_index_in_file)
      count_indices <- c(1, 1, (end_time_index_in_file - start_time_index_in_file + 1))

      # Read the actual weather variable data
      # Assumes the NetCDF variable name matches current_variable_name (e.g., "pr", "Tmin")
      data_values <- tryCatch(
        ncdf4::ncvar_get(nc_file_obj,
          varid = current_variable_name,
          start = start_indices,
          count = count_indices
        ),
        error = function(e) {
          warning(paste("Could not read variable '", current_variable_name, "' from file:", nc_file_path, "-", e$message))
          NULL
        }
      )
      ncdf4::nc_close(nc_file_obj) # Close the NetCDF file

      if (is.null(data_values)) next

      # Create a tibble for the data from this file
      # The timestamps should correspond to the slice read
      selected_timestamps <- nc_timestamps[start_time_index_in_file:end_time_index_in_file]

      # Check if length of data_values matches selected_timestamps
      if (length(data_values) != length(selected_timestamps)) {
        warning(paste(
          "Mismatch between data length and timestamp length for variable '",
          current_variable_name, "' in file:", nc_file_path, ". Skipping this file's data for this variable."
        ))
        next
      }

      single_file_df <- tibble::tibble(
        date = selected_timestamps,
        lat = closest_point_info$nc_lat, # Actual grid cell latitude
        lon = closest_point_info$nc_lon, # Actual grid cell longitude
        "{current_variable_name}" := data_values # Dynamic column name
      )
      data_from_files_list[[length(data_from_files_list) + 1]] <- single_file_df
    } # End loop over files for one variable

    # Combine data from all files for the current variable (if any were read)
    if (length(data_from_files_list) > 0) {
      all_periods_for_variable <- dplyr::bind_rows(data_from_files_list) |>
        dplyr::distinct(date, .keep_all = TRUE) # In case of overlapping files for same variable
      all_variables_data_list[[current_variable_name]] <- all_periods_for_variable
    }
  } # End loop over variables

  # Join data from all requested variables into a single data.frame
  if (length(all_variables_data_list) == 0) {
    warning("No data could be extracted for any of the requested variables and date range.")
    return(tibble::tibble()) # Return an empty tibble
  }

  # Use purrr::reduce for joining all data frames in the list
  final_weather_df <- all_variables_data_list |>
    purrr::reduce(dplyr::full_join, by = c("date", "lat", "lon")) |>
    dplyr::arrange(date) # Sort by date

  # Final filter to ensure data is strictly within the originally requested date_range,
  # as file slicing might have included slightly more at the boundaries.
  final_weather_df <- final_weather_df |>
    dplyr::filter(date >= start_date_requested, date <= end_date_requested)

  return(final_weather_df)
}
