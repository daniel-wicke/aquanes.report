
ui_report <- function(...) {
  fluidPage(
    titlePanel("Parameterise report"),

    sidebarLayout(
      sidebarPanel(
        selectInput("report_timezone", label = "Select a timezone",
                    choices = aquanes.report::get_valid_timezones()$TZ.,
                    selected = "UTC"),
        selectInput("report_aggregation", label = "Select temporal aggregation",
                    choices = c("raw", "hour", "day", "month"),
                    selected = "raw"),
        dateRangeInput('report_daterange',
                       label = 'Date range input: yyyy-mm-dd',
                       start = "2016-09-01",
                       end = "2016-10-30"),
        selectInput("report_sitenames", label = "Select sampling points",
                    choices = unique(haridwar_raw_list$SiteName),
                    multiple = TRUE,
                    selected = unique(haridwar_raw_list$SiteName)),
        h3("Select parameters"),
        selectInput("report_parameters_online", label = "Online",
                    choices = unique(haridwar_raw_list$ParameterName[haridwar_raw_list$Source == "online"]),
                    multiple = TRUE,
                    selected = unique(haridwar_raw_list$ParameterName[haridwar_raw_list$Source == "online"])[3]),
        selectInput("report_parameters_offline", label = "Offline",
                    choices = unique(haridwar_raw_list$ParameterName[haridwar_raw_list$Source == "offline"]),
                    multiple = TRUE,
                    selected = unique(haridwar_raw_list$ParameterName[haridwar_raw_list$Source == "offline"])[1]),
        radioButtons("report_format", "Report format", c("HTML", "PDF", "Word"),
                      inline = TRUE),
        downloadButton("report_download", "Generate & download report"),
        downloadButton("report_zip", "Download standalone report (zip)")),
      mainPanel(
        #h1("Report preview"),
        #downloadButton("report_zip", "Download report zip"),
        htmlOutput("report_preview")
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
    para_idx <- report_tz()[,"ParameterName"] %in%  c(input$report_parameters_online, input$report_parameters_offline)
    row_idx <- date_idx & site_idx & para_idx
    report_tz()[row_idx, c("DateTime",
                           "measurementID",
                           "SiteName",
                           "ParameterName",
                           "ParameterUnit",
                           "ParameterValue",
                           "DataType")] %>%
      dplyr::filter_("!is.na(ParameterValue)") %>%
      # dplyr::mutate_("ParaName_Unit" = "sprintf('%s (%s)', ParameterName, ParameterUnit)")  %>%
      dplyr::select_("DateTime",
                     "measurementID",
                     "SiteName",
                     "ParameterName",
                     "ParameterUnit",
                     "ParameterValue",
                     "DataType")

  })


  report_data_agg <- reactive({


    if (input$report_aggregation != "raw") {
      res <- aquanes.report::group_datetime(df = report_data(),
                                     by = input$report_aggregation,
                                     fun = "median")
    } else {
      res <- report_data()
    }
   return(res)
  })


  output$report_zip <- downloadHandler(
    filename = function() {
      datetime <- format(Sys.time(), format = "%Y%m%d%H%M%S")
      paste("report_", datetime, ".zip", sep = "")
    },

    content = function(zfile) {
      tdir <- tempdir()


      #conf_list <- aquanes.report::report_config_template()

      # Set up config parameters & save in text file
      conf_list <- list(report_sitenames = input$report_sitenames,
                        report_aggregation = input$report_aggregation,
                        report_parameters_online = input$report_parameters_online,
                        report_parameters_offline = input$report_parameters_offline,
                        report_daterange = input$report_daterange,
                        report_timezone = input$report_timezone)

      conf_name <- "report_config.txt"
      conf_file <- file.path(tdir, conf_name)

      aquanes.report::report_config_to_txt(config_list = conf_list,
                                           output_file = conf_file)


      batchDir <- file.path(tdir, "batch")
      reportPath <- file.path(getwd(), "report/report.Rmd")
      files_to_zip <- create_report_batch(batchDir = batchDir,
                                          report_path = reportPath,
                                          report_config_path = conf_file,
                                          open_in_explorer = FALSE)

      dir.old <- setwd(batchDir)
      on.exit(dir.old)


      #cat(tdir, file = stderr())
      zip(zipfile = zfile,
          files = files_to_zip)

    },
    contentType = "application/zip")





  create_report <- reactive({
    tdir <- tempdir()
    tempReport <- file.path(tdir, "report.Rmd")
    file.copy(from = "report/report.Rmd",
              to = tempReport,
              overwrite = TRUE)

    # Set up parameters to pass to Rmd document
    params <- list(run_as_standalone = FALSE,
                   report_data = report_data_agg(),
                   report_aggregation = input$report_aggregation,
                   report_sitenames = input$report_sitenames,
                   report_parameters_online = input$report_parameters_online,
                   report_parameters_offline = input$report_parameters_offline,
                   report_daterange = input$report_daterange,
                   report_timezone = input$report_timezone)

    # Knit the document, passing in the `params` list, and eval it in a
    # child of the global environment (this isolates the code in the document
    # from the code in this app).
    ofile <- file.path(tdir, "automated_report.html")
    rmarkdown::render(tempReport,
                      output_file = ofile,
                      params = params,
                      envir = new.env(parent = globalenv()))
    #includeHTML(ofile)
    ofile
  })


  output$report_preview <- renderUI(
    includeHTML(create_report())
  )

  # output$report_download <- downloadHandler(filename = "automated_report.html",
  #                                           content = function(file) {
  #                                             file.copy(from = create_report(),
  #                                                       to =  file)
  #                                             })


  output$report_download <- downloadHandler(
    filename = function() {
      paste('automated_report', sep = '.', switch(
        input$report_format, PDF = 'pdf', HTML = 'html', Word = 'docx'
      ))
    },

    content = function(file) {


      if (input$report_format == "HTML") {
        file.copy(from = create_report(), to =  file)
      } else {

      tdir <- tempdir()
      tempReport <- file.path(tdir, "report.Rmd")
      file.copy(from = "report/report.Rmd",
                to = tempReport,
                overwrite = TRUE)

      # Set up parameters to pass to Rmd document
      params <- list(run_as_standalone = FALSE,
                     report_data = report_data_agg(),
                     report_aggregation = input$report_aggregation,
                     report_sitenames = input$report_sitenames,
                     report_parameters_online = input$report_parameters_online,
                     report_parameters_offline = input$report_parameters_offline,
                     report_daterange = input$report_daterange,
                     report_timezone = input$report_timezone)

      # Knit the document, passing in the `params` list, and eval it in a
      # child of the global environment (this isolates the code in the document
      # from the code in this app).
      ofile <-  file.path(tdir, paste('automated_report', sep = '.',
                      switch(input$report_format,
                             PDF = 'pdf',
                             Word = 'docx')))


      output_format <- switch(input$report_format,
                              PDF = "pdf_document",
                              Word = "word_document")

      rmarkdown::render(input = tempReport,
                        output_file = ofile,
                        output_format = output_format,
                        params = params,
                        envir = new.env(parent = globalenv()))
      file.copy(from = ofile,
                  to = file)

      }
    }
  )
}
