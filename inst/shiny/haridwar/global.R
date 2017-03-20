use_live_data <- FALSE

if (use_live_data) {

haridwar_raw_list <- import_data_haridwar()

saveRDS(haridwar_raw_list, file = "data/haridwar_raw_list.Rds")
} else {
  haridwar_raw_list <- readRDS("data/haridwar_raw_list.Rds")
}
