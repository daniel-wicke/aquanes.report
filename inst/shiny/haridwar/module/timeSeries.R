server_timeSeries <- function(...) {


  ts_tz <- reactive({
    aquanes.report::change_timezone(df = haridwar_raw_list,
                                    tz = input$timezone)
  })
  
  
  ts_tz_agg <- reactive({
    
    if(input$temporal_aggregation != "raw") {
    aquanes.report::group_datetime(df = ts_tz(),
                                   by = input$temporal_aggregation)
    } else {
      ts_tz()
    }
    
  })


  # ts_errors <- reactive({
  #   condi <- ts_tz()[, "ParameterCode"] == "errcode" & ts_tz()[,"ParameterValue"] != 0
  #   ts_tz()[ts_tz()$ParameterCode == "errcode" & ts_tz()$ParameterValue != 0,]
  # })

  ts_data1 <- reactive({


    # input <- list(timezone = "UTC",
    #               daterange = c("2016-09-05","2016-10-05"),
    #               sitename = unique(haridwar_raw_list$SiteName),
    #               parameter1 = unique(haridwar_raw_list$ParameterName)[1])


    date_idx <- as.Date(ts_tz_agg()[,"DateTime"]) >= input$daterange[1] & as.Date(ts_tz_agg()[,"DateTime"]) <= input$daterange[2]
    site_idx <- ts_tz_agg()[,"SiteName"] %in% input$sitename
    para_idx <- ts_tz_agg()[,"ParameterName"] %in%  input$parameter1
    row_idx <- date_idx & site_idx & para_idx
    ts_tz_agg()[row_idx, c("DateTime",
                                        "measurementID",
                                        "SiteName",
                                        "ParameterName",
                                        "ParameterUnit",
                                        "ParameterValue")] %>%
      dplyr::filter_("!is.na(ParameterValue)") %>%
      dplyr::mutate_("SiteName_ParaName_Unit" = "sprintf('%s: %s (%s)', SiteName, ParameterName, ParameterUnit)")  %>%
      dplyr::select_("DateTime",
                     "measurementID",
                     "SiteName_ParaName_Unit",
                     "ParameterValue") %>%
      tidyr::spread_(key_col = "SiteName_ParaName_Unit",
                     value_col = "ParameterValue")


  })

  ts_data2 <- reactive({

    date_idx <- as.Date(ts_tz_agg()[,"DateTime"]) >= input$daterange[1] & as.Date(ts_tz_agg()[,"DateTime"]) <= input$daterange[2]
    site_idx <- ts_tz_agg()[,"SiteName"] %in% input$sitename
    para_idx <- ts_tz_agg()[,"ParameterName"] %in%  input$parameter2
    row_idx <- date_idx & site_idx & para_idx
    ts_tz_agg()[row_idx, c("DateTime",
                                  "measurementID",
                                  "SiteName",
                                  "ParameterName",
                                  "ParameterUnit",
                                  "ParameterValue")] %>%
      dplyr::filter_("!is.na(ParameterValue)") %>%
      dplyr::mutate_("SiteName_ParaName_Unit" = "sprintf('%s: %s (%s)', SiteName, ParameterName, ParameterUnit)")  %>%
      dplyr::select_("DateTime",
                     "measurementID",
                     "SiteName_ParaName_Unit",
                     "ParameterValue") %>%
      tidyr::spread_(key_col = "SiteName_ParaName_Unit",
                     value_col = "ParameterValue")


  })




ts_data1_xts <- reactive({


  xts::xts(x = ts_data1()[,c(-1,-2), drop = FALSE],
           order.by = ts_data1()$DateTime,
           tzone = base::attr(ts_data1()$DateTime,
                              "tzone"))

  })



  output$dygraph1 <- renderDygraph({
    dygraph(data = ts_data1_xts(),
            group = "dy_group",
           # main = unique(ts_data()$LocationName),
                    ylab = "Parameter value") %>%
             # dySeries("V1",
             #          label = sprintf("%s (%s)",
             #                          unique(ts_data()$ParameterName),
             #                          unique(ts_data()$ParameterUnit))) %>%
             dyLegend(show = "always",
                      hideOnMouseOut = FALSE,
                      width = 900) %>%
             dyRangeSelector(dateWindow = input$daterange) %>%
             dyOptions(useDataTimezone = TRUE,
                       drawPoints = TRUE,
                       pointSize = 2) #%>%
             # dyEvent(x = ts_errors()$DateTime,
             #         label = ts_errors()$ParameterValue,
             #         labelLoc = "bottom")
  })


  ts_data2_xts <- reactive({


    xts::xts(x = ts_data2()[,c(-1,-2), drop = FALSE],
             order.by = ts_data2()$DateTime,
             tzone = base::attr(ts_data2()$DateTime,
                                "tzone"))

  })



  output$dygraph2 <- renderDygraph({
    dygraph(data = ts_data2_xts(),
            group = "dy_group",
            # main = unique(ts_data()$LocationName),
            ylab = "Parameter value") %>%
      # dySeries("V1",
      #          label = sprintf("%s (%s)",
      #                          unique(ts_data()$ParameterName),
      #                          unique(ts_data()$ParameterUnit))) %>%
      dyLegend(show = "always",
               hideOnMouseOut = FALSE,
               width = 900) %>%
      dyRangeSelector(dateWindow = input$daterange) %>%
      dyOptions(useDataTimezone = TRUE,
                drawPoints = TRUE,
                pointSize = 2) #%>%
    # dyEvent(x = ts_errors()$DateTime,
    #         label = ts_errors()$ParameterValue,
    #         labelLoc = "bottom")
  })



  output$report <- downloadHandler(
    # For PDF output, change this to "report.pdf"
    filename = "report.html",
    content = function(file) {
      # Copy the report file to a temporary directory before processing it, in
      # case we don't have write permissions to the current working dir (which
      # can happen when deployed).
      tempReport <- file.path(tempdir(), "dygraph.Rmd")
      file.copy("report/dygraph.Rmd", tempReport, overwrite = TRUE)

      # Set up parameters to pass to Rmd document
      params <- list(myData1 = ts_data1_xts(),
                     myData2 = ts_data2_xts(),
                     myDateRange = input$daterange,
                     myTimezone = input$timezone)

      # Knit the document, passing in the `params` list, and eval it in a
      # child of the global environment (this isolates the code in the document
      # from the code in this app).
      rmarkdown::render(tempReport, output_file = file,
                        params = params,
                        envir = new.env(parent = globalenv())
      )
    })




    export_df <- reactive({
      switch(input$dataset,
             "data_plot1" = ts_data1_xts(),
             "data_plot2" = ts_data2_xts())})


    output$downloadData <- downloadHandler(
      filename = function() {
        paste(input$dataset, "_", input$timezone, ".csv",
              sep = "")
      },
      content = function(file) {
        write.csv(ggplot2::fortify(export_df()), file)
      }
    )


}

ui_timeSeries <- function(...) {
  fluidPage(
  titlePanel("Time series"),

  sidebarLayout(
    sidebarPanel(
      tags$head(tags$style(type="text/css", "
             #loadmessage {
                           position: fixed;
                           top: 0px;
                           left: 0px;
                           width: 100%;
                           padding: 5px 0px 5px 0px;
                           text-align: center;
                           font-weight: bold;
                           font-size: 100%;
                           color: #000000;
                           background-color: #CCFF66;
                           z-index: 105;
}
")),
      selectInput("timezone", label = "Select a timezone",
                  choices = aquanes.report::get_valid_timezones()$TZ.,
                  selected = "UTC"),
      selectInput("temporal_aggregation", label = "Select temporal aggregation",
                  choices = c("raw", "minute", "hour", "day", "month", "year"),
                  selected = "day"),
      dateRangeInput('daterange',
                     label = 'Date range input: yyyy-mm-dd',
                     start = "2016-09-05",
                     end = "2016-10-31"),
      selectInput("sitename", label = "Select a sampling point",
                  choices = unique(haridwar_raw_list$SiteName),
                  multiple = TRUE,
                  selected = unique(haridwar_raw_list$SiteName)),
      selectInput("parameter1", label = "Select a parameter(s) for plot 1",
                  choices = unique(haridwar_raw_list$ParameterName),
                  multiple = TRUE,
                  selected = unique(haridwar_raw_list$ParameterName)[c(3,4,24)]),
      selectInput("parameter2", label = "Select a parameter(s) for plot 2",
                  choices = unique(haridwar_raw_list$ParameterName),
                  multiple = TRUE,
                  selected = unique(haridwar_raw_list$ParameterName)[c(30)]),
      downloadButton("report", "Download plot"),
      selectInput("dataset", "Choose a dataset to download:",
                  choices = c("data_plot1", "data_plot2")),
      downloadButton('downloadData', 'Download data'),
      conditionalPanel(condition = "$('html').hasClass('shiny-busy')",
                       tags$div("Loading... (this may take ~ 1 minute)",
                                id = "loadmessage"))
    ),
    mainPanel(
       dygraphOutput("dygraph1"),
       h1(textOutput("")),
       h1(textOutput("")),
       dygraphOutput("dygraph2")
    )
  )
)
}

