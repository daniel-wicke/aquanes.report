library(dygraphs)

shinyUI(fluidPage(

  titlePanel("Time series"),

  sidebarLayout(
    sidebarPanel(
      selectInput("parameter", label = "Select a parameter",
                  choices = unique(haridwar_raw_list$ParameterName),
                  multiple = TRUE,
                  selected = unique(haridwar_raw_list$ParameterName)[2]),
      selectInput("sitename", label = "Select a site",
                  choices = unique(haridwar_raw_list$SiteName),
                  multiple = TRUE,
                  selected = unique(haridwar_raw_list$SiteName)),
      selectInput("timezone", label = "Select a timezone",
                  choices = aquanes.report::get_valid_timezones()$TZ.,
                  selected = "UTC"),
      uiOutput("dateRange")
      # dateRangeInput('daterange',
      #                label = 'Date range input: yyyy-mm-dd',
      #                start = as.Date(min(haridwar_raw_list$DateTime))-1,
      #                end = as.Date(max(haridwar_raw_list$DateTime))+1)
    ),
    mainPanel(
      dygraphOutput("dygraph")
    )
  )
))
