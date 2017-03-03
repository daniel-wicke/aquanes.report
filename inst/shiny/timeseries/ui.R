library(dygraphs)
#haridwar_raw_list <- readRDS("data/haridwar_raw_list.Rds")

shinyUI(fluidPage(

  titlePanel("Time series"),

  sidebarLayout(
    sidebarPanel(
      selectInput("timezone", label = "Select a timezone",
                  choices = aquanes.report::get_valid_timezones()$TZ.,
                  selected = "UTC"),
      uiOutput("dateRange"),
      selectInput("parameter", label = "Select a parameter",
                  choices = unique(haridwar_raw_list$ParameterName),
                  multiple = TRUE,
                  selected = unique(haridwar_raw_list$ParameterName)[c(3,4,24)]),
      selectInput("sitename", label = "Select a sampling point",
                  choices = unique(haridwar_raw_list$SiteName),
                  multiple = TRUE,
                  selected = unique(haridwar_raw_list$SiteName)),
      downloadButton("report", "Download plot")
    ),
    mainPanel(
      dygraphOutput("dygraph")
    )
  )
))
