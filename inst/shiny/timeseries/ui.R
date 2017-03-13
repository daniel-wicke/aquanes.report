library(dygraphs)
#haridwar_raw_list <- readRDS("data/haridwar_raw_list.Rds")

shinyUI(fluidPage(

  titlePanel("Time series"),

  sidebarLayout(
    sidebarPanel(
      selectInput("timezone", label = "Select a timezone",
                  choices = aquanes.report::get_valid_timezones()$TZ.,
                  selected = "UTC"),
      dateRangeInput('daterange',
                     label = 'Date range input: yyyy-mm-dd',
                     start = "2016-09-05",
                     end = Sys.Date()),
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
      downloadButton("report", "Download plot")
    ),
    mainPanel(
      dygraphOutput("dygraph1"),
      h1(textOutput("")),
      h1(textOutput("")),
      dygraphOutput("dygraph2")
    )
  )
))
