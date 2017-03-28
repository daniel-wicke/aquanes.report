#'Group DateTime by user defined period (year, month, day, hour, minute)
#' @param df a data frame as retrieved by import_data_haridwar()
#' @param by an aggregation time step of "year", "month", "day", "hour", "minute"
#' (default: "day)
#' @param fun function to be used for grouping measurement data of column ParameterValue
#' (default: median)
#' (default: system.file("shiny/haridwar/.my.cnf", package = "aquanes.report"))
#' @param col_datetime column name of datetime column (default: DateTime)
#' @param col_datatype column name of data type column (default: DateType)
#' @return returns data frame with data aggregated according to user defined
#' aggregation time step
#' @import dplyr
#' @export

group_datetime <- function(df,
                           by = "day",
                           fun = "median",
                           col_datetime = "DateTime",
                           col_datatype = "DataType") {


by <- tolower(by)

grp_list <- list(year = "%Y-01-01 00:00:00",
                 month = "%Y-%m-01 00:00:00",
                 day = "%Y-%m-%d 00:00:00",
                 hour = "%Y-%m-%d %H:00:00",
                 minute = "%Y-%m-%d %H:%M:00")

if (!by %in% names(grp_list)) {

  msg <- sprintf("'%s' is no valid aggregation time step!\n Please select one of: %s for parameter 'by')",
                 by,
                 paste(names(grp_list), collapse = ", "))
  stop(msg,
       call. = FALSE)


}

datetime_org <- df[,col_datetime]
tz_org <- base::check_tzones(datetime_org)
df[,col_datetime] <- as.POSIXct(format(df[,col_datetime],
                                        format = grp_list[[by]]),
                                tz = tz_org)


if (by == "day") by <- "dai"

df[,col_datatype] <- sprintf("%s (%sly %s)", df[,col_datatype], by, fun)


df <- df %>% dplyr::group_by_(.dots = dplyr::setdiff(names(df), "ParameterValue")) %>%
             dplyr::summarise_("ParameterValue" = sprintf("stats::%s(ParameterValue)", fun)) %>%
             as.data.frame()

return(df)
}

