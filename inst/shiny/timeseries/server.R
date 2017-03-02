library(dygraphs)
library(xts)


shinyServer(function(input, output) {

  output$dateRange <- renderUI({
    dateRangeInput('daterange',
                   label = 'Date range input: yyyy-mm-dd',
                   start = as.Date(min(haridwar_raw_list$DateTime),tz = input$timezone),
                   end = as.Date(max(haridwar_raw_list$DateTime),tz = input$timezone))
  })


  ts_data <- reactive({


    row_idx <- haridwar_raw_list[,"ParameterName"] %in%  input$parameter & haridwar_raw_list[,"SiteName"] %in% input$sitename

    tmp <- haridwar_raw_list[row_idx, c("DateTime",
                                        "measurementID",
                                        "SiteName",
                                        "ParameterName",
                                        "ParameterValue")] %>%
      dplyr::filter_("!is.na(ParameterValue)") %>%
      dplyr::mutate_("ParaName_SiteName" = "sprintf('%s (%s)', ParameterName, SiteName)")  %>%
      dplyr::select_("DateTime",
                     "measurementID",
                     "ParaName_SiteName",
                     "ParameterValue") %>%
      tidyr::spread_(key_col = "ParaName_SiteName",
                     value_col = "ParameterValue")


    aquanes.report::change_timezone(df = tmp,
                                    tz = input$timezone)
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
             dyRangeSelector(dateWindow = c(as.POSIXct(input$daterange[1],
                                                     tz = input$timezone),
                                            as.POSIXct(input$daterange[2],
                                                       tz = input$timezone))) %>%
             dyOptions(useDataTimezone = TRUE, 
                       drawPoints = TRUE, 
                       pointSize = 2)
  })

})
