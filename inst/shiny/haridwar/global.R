use_live_data <- FALSE

if (use_live_data) {
library(aquanes.report)
library(dplyr)
library(readxl)
library(tidyr)


#setwd(dir = "C:/Users/mrustl/Desktop/wc_aquanes")

###############################################################################
###############################################################################
###############################################################################
#### Site 1: Haridwar
###############################################################################
###############################################################################
###############################################################################

###############################################################################
#### 1) Import analytics data from EXCEL spreadsheet
###############################################################################

### Define directory (variable "xlsDir") and filename (variable "xlsName) of
### EXCEl spreadsheet to be imported
xlsDir <- "data"
xlsName <- "161101Monitoring_AquaNES_4014_Haridwar_KWB.xlsx"

xlsPath <- file.path(xlsDir, xlsName)


### Use case 1) Import a single sheet "Temp_Hach"
# temp <- import_sheets(xlsPath = xlsPath,
#                       sheets_analytics = "Temp_Hach")

### Use case 2) Import a multiple sheets from a .xls file
excludedSheets <- c("Parameters",
                    "Location",
                    "Sites",
                    "Summary",
                    "Observations",
                    "dP_Manometer_2.Regelung",
                    "Flow"
)

all_sheets <- readxl::excel_sheets(xlsPath)

analytics_to_import <- all_sheets[!all_sheets %in% excludedSheets]



analytics_4014 <- import_sheets(xlsPath = xlsPath,
                                sheets_analytics = analytics_to_import)



###############################################################################
#### 2) Operational data
###############################################################################

#### 2.1) Import

operation <- import_operation(mysql_conf = ".my.cnf")


drop.cols <- c("DateTime", "AnlagenID", "LocationName", "id", "localTime")

operation_list <- operation %>%
  tidyr::gather_(key_col = "ParameterCode",
                 value_col = "ParameterValue",
                 gather_cols = dplyr::setdiff(names(.),drop.cols))

operation_para_names <- read.csv(file = "data/operation_parameters.csv",
                                 stringsAsFactors = FALSE )


operation_list <- operation_list %>%
  left_join(operation_para_names) %>%
  mutate_(Source = "as.character('online')")


haridwar_raw_list <- plyr::rbind.fill(operation_list,
                                      analytics_4014 %>%
                                      dplyr::mutate_(Source = "as.character('offline')"))

haridwar_raw_list$DataType <- "raw"

drop.cols <- c("id", "AnlagenID", "Who", "Comments","localTime", "LocationName", "LocationID")

haridwar_raw_list  <- haridwar_raw_list[,dplyr::setdiff(names(haridwar_raw_list),drop.cols)]  %>%
                      dplyr::filter_("!is.na(ParameterValue)")

haridwar_raw_list$SiteName[is.na(haridwar_raw_list$SiteName)] <- "Online"

saveRDS(haridwar_raw_list, file = "data/haridwar_raw_list.Rds")
} else {
  haridwar_raw_list <- readRDS("data/haridwar_raw_list.Rds")
}
