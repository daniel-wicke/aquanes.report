#'Runs Shiny app for an AQUANES site
#'@param siteName site name for shiny app (default: "haridwar")
#'@param use_live_data should live data be used (default: FALSE)
#'@param launch.browser If true, the system's default web browser will be
#'launched automatically after the app is started (default: TRUE)
#'@param ... further arguments passed to shiny::runApp()
#'@importFrom shiny runApp
#'@export
run_shinyapp <- function(siteName = "haridwar",
                         use_live_data = FALSE,
                         launch.browser = TRUE,
                         ...) {


  use_live_data <- toupper(use_live_data)

  shinyDir <- system.file("shiny", package = "aquanes.report")
  appDir <- file.path(shinyDir, siteName)


  if (!siteName %in% dir(shinyDir)) {
    msg <- sprintf("Could not find shiny app directory for %s.\n
                    Please select for parameter 'siteName' one of:\n'%s'",
                    siteName,
                    paste(dir(shinyDir), collapse = ", "))

    stop(msg, call. = FALSE)
  }


  global_path <-  file.path(appDir, "global.R")


  if(file.exists(global_path) == FALSE) {
    stop(sprintf("Could not find a 'global.R' in: %s", appDir),
         call. = FALSE)
  }


  ### adapt "global.R" to use live data or not
  global_string <- readLines(global_path)
  replace_line <- grep(pattern = "use_live_data\\s*<-", global_string)
  global_string[replace_line] <- sprintf("use_live_data <- %s", use_live_data)
  writeLines(global_path,text = global_string)




  shiny::runApp(appDir,
                display.mode = "normal",
                launch.browser = launch.browser,
                ...)
}
