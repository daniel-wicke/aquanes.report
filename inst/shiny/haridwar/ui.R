#jQuery <- includeScript("http://code.jquery.com/jquery-2.1.3.js")
googleAnalytics <- includeScript("tools/google-analytics.js")

shinyUI(
  fluidPage(
    #tags$head(jQuery),
    tags$head(googleAnalytics),
    uiOutput("mainPage")
  )
)
