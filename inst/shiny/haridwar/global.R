use_live_data <- TRUE

if (use_live_data) {

library(aquanes.report)

analytics <- file.path(getwd(),
                       "data/161101Monitoring_AquaNES_4014_Haridwar_KWB.xlsx")

mySQL <- file.path(getwd(),
                   ".my.cnf")

op_meta <- file.path(getwd(),
                     "data/operation_parameters.csv")

haridwar_raw_list <- aquanes.report::import_data_haridwar(analytics_path = analytics,
                                          operation_mySQL_conf = mySQL,
                                          operation_meta_path = op_meta)

saveRDS(haridwar_raw_list, file = "data/haridwar_raw_list.Rds")
} else {
  haridwar_raw_list <- readRDS("data/haridwar_raw_list.Rds")
}
