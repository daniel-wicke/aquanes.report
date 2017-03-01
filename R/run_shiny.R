#'Runs Shiny App
#'@param appName name of shiny app (default: "visualise")
#'@param launch.browser If true, the system's default web browser will be
#'launched automatically after the app is started (default: TRUE)
#'@param ... further arguments passed to shiny::runApp()
#'@importFrom shiny runApp
#'@export
run_shinyapp <- function(appName = "timeseries",
                         launch.browser = TRUE,
                         ...) {
  appDir <- system.file("shiny", appName, package = "aquanes.report")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `mypackage`.",
         call. = FALSE)
  }

  shiny::runApp(appDir,
                display.mode = "normal",
                launch.browser = launch.browser,
                ...)
}
