library(dplyr)
library(tidyr)
library(dygraphs)
library(xts)
library(aquanes.report)
library(shiny)
#haridwar_raw_list <- readRDS("data/haridwar_raw_list.Rds")


shinyServer(function(input, output) {

  output$dateRange <- renderUI({
    dateRangeInput('daterange',
                   label = 'Date range input: yyyy-mm-dd',
                   start = as.Date(min(haridwar_raw_list$DateTime),tz = input$timezone),
                   end = as.Date(max(haridwar_raw_list$DateTime),tz = input$timezone))
  })


  
  ts_tz <- reactive({ 
    aquanes.report::change_timezone(df = haridwar_raw_list,
                                    tz = input$timezone)
  })
  
  
  # ts_errors <- reactive({
  #   condi <- ts_tz()[, "ParameterCode"] == "errcode" & ts_tz()[,"ParameterValue"] != 0
  #   ts_tz()[ts_tz()$ParameterCode == "errcode" & ts_tz()$ParameterValue != 0,]
  # })
  
  ts_data <- reactive({


    row_idx <- ts_tz()[,"ParameterName"] %in%  input$parameter & ts_tz()[,"SiteName"] %in% input$sitename

    ts_tz()[row_idx, c("DateTime",
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




ts_data_xts <- reactive({


  xts::xts(x = ts_data()[,c(-1,-2)],
           order.by = ts_data()$DateTime,
           tzone = base::attr(ts_data()$DateTime,
                              "tzone"))

  })



  output$dygraph <- renderDygraph({
    dygraph(data = ts_data_xts(),
           # main = unique(ts_data()$LocationName),
                    ylab = "Parameter value") %>%
             # dySeries("V1",
             #          label = sprintf("%s (%s)",
             #                          unique(ts_data()$ParameterName),
             #                          unique(ts_data()$ParameterUnit))) %>%
             dyLegend(show = "always", hideOnMouseOut = FALSE) %>%
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
      params <- list(myData = ts_data_xts(),
                     myDateRange = input$daterange,
                     myTimezone = input$timezone)
      
      # Knit the document, passing in the `params` list, and eval it in a
      # child of the global environment (this isolates the code in the document
      # from the code in this app).
      rmarkdown::render(tempReport, output_file = file,
                        params = params,
                        envir = new.env(parent = globalenv())
      )
    }
  )

})
