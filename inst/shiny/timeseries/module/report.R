
ui_report <- function(...) {
  fluidPage(
    titlePanel("Parameterise report"),

    sidebarLayout(
      sidebarPanel(
#         tags$head(tags$style(type="text/css", "
#                              #loadmessage {
#                              position: fixed;
#                              top: 0px;
#                              left: 0px;
#                              width: 100%;
#                              padding: 5px 0px 5px 0px;
#                              text-align: center;
#                              font-weight: bold;
#                              font-size: 100%;
#                              color: #000000;
#                              background-color: #CCFF66;
#                              z-index: 105;
# }
# ")),
        selectInput("report_timezone", label = "Select a timezone",
                    choices = aquanes.report::get_valid_timezones()$TZ.,
                    selected = "UTC"),
        dateRangeInput('report_daterange',
                       label = 'Date range input: yyyy-mm-dd',
                       start = "2016-09-01",
                       end = "2016-10-30"),
        selectInput("report_sitenames", label = "Select sampling points",
                    choices = unique(haridwar_raw_list$SiteName),
                    multiple = TRUE,
                    selected = unique(haridwar_raw_list$SiteName)[1]),
        selectInput("report_parameters", label = "Select parameters",
                    choices = unique(haridwar_raw_list$ParameterName),
                    multiple = TRUE,
                    selected = unique(haridwar_raw_list$ParameterName)[3])#,
        #downloadButton("report_download", "Download report")#,
        # selectInput("dataset", "Choose a dataset to download:",
        #             choices = c("data_plot1", "data_plot2")),
        # downloadButton('downloadData', 'Download data'),
        # conditionalPanel(condition = "$('html').hasClass('shiny-busy')",
        #                  tags$div("Loading... (this may take ~ 1 minute)",
        #                           id = "loadmessage"))
        ),
      mainPanel(
        h1(textOutput("Report preview")),
        uiOutput("report_preview")
      )
      )
    )
  }

server_report <- function(...) {


  report_tz <- reactive({
    aquanes.report::change_timezone(df = haridwar_raw_list,
                                    tz = input$report_timezone)
  })



  report_data <- reactive({


    date_idx <- as.Date(report_tz()[,"DateTime"]) >= input$report_daterange[1] & as.Date(report_tz()[,"DateTime"]) <= input$report_daterange[2]
    site_idx <- report_tz()[,"SiteName"] %in% input$report_sitenames
    para_idx <- report_tz()[,"ParameterName"] %in%  input$report_parameters
    row_idx <- date_idx & site_idx & para_idx
    report_tz()[row_idx, c("DateTime",
                           "measurementID",
                           "SiteName",
                           "ParameterName",
                           "ParameterUnit",
                           "ParameterValue")] %>%
      dplyr::filter_("!is.na(ParameterValue)") %>%
      # dplyr::mutate_("ParaName_Unit" = "sprintf('%s (%s)', ParameterName, ParameterUnit)")  %>%
      dplyr::select_("DateTime",
                     "measurementID",
                     "SiteName",
                     "ParameterName",
                     "ParameterUnit",
                     "ParameterValue")

  })


  output$report_preview <- renderUI({
    tdir <- tempdir()
    tempReport <- file.path(tdir, "report.Rmd")
    file.copy(from = "report/report.Rmd",
              to = tempReport,
              overwrite = TRUE)

    # Set up parameters to pass to Rmd document
    params <- list(run_as_standalone = FALSE,
                   report_data = report_data(),
                   report_sitenames = input$report_sitenames,
                   report_parameters = input$report_parameters,
                   report_daterange = input$report_daterange,
                   report_timezone = input$report_timezone)

    # Knit the document, passing in the `params` list, and eval it in a
    # child of the global environment (this isolates the code in the document
    # from the code in this app).
    ofile <- file.path(tdir, "report.html")
    rmarkdown::render(tempReport,
                      output_file = ofile,
                      params = params,
                      envir = new.env(parent = globalenv()))
    includeHTML(ofile)
  })




}
