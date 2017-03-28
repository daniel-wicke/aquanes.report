# aquanes.report
Collects, aggregates and visualises operational analytical data from water suppliers (including a standardised reporting document)

[![Build Status](https://travis-ci.org/KWB-R/aquanes.report.svg?branch=master)](https://travis-ci.org/KWB-R/aquanes.report)


## Step 1) Installation of R package "devtools" 

The R package "devtools" is required for downloading and installing the R package "aquanes.report" from Github. 
For installing it execute the following lines of code in R(Studio):
```r
if (!require("devtools")) {
  install.packages("devtools", repos = "https://cloud.r-project.org")
}
```

## Step 2) Installation of R package "aquanes.report"
### 2.1) Specific release 

In case you want to install a specific release you need to specify the 
parameter "ref", which needs to be set to a valid release (check here: [releases](https://github.com/KWB-R/aquanes.report/releases)) by running the following code in R(Studio). This tutorial at least requires release version [v.0.2.0-alpha](https://github.com/KWB-R/aquanes.report/releases/tag/v.0.2.0-alpha)):
```r
devtools::install_github("kwb-r/aquanes.report", 
                         ref = "v.0.2.0-alpha",
                         dependencies = TRUE)
```

### 2.2) Development version

If you want to install the latest (possibly unstable!) development version, 
execute the following lines of code in R(Studio):

```r
devtools::install_github("kwb-r/aquanes.report", 
                         dependencies = TRUE)
```


## Step 3) Check the installation folder of the package in R(Studio) with:
```r
system.file(package = "aquanes.report")
``` 
## Step 4) Two files need to be copied:

### 4.1) mySQL configuration file ('.my.cnf')

The '.my.cnf' is required to establish a connection to the mySQL database for querying 
the operational data for the Haridwar site. It needs to be copied into the following 
directory:
```r
system.file("shiny/haridwar", package = "aquanes.report")
``` 
### 4.2) Analytics spreadsheet file ('analytics.xlsx')

The 'analytics.xlsx' file contains the analytics data for the Haridwar site and needs to 
be copied into the following directory:

```r
system.file("shiny/haridwar/data", package = "aquanes.report")
``` 

## Step 5) Launch the shiny app locally

### 5.1) First usage

If you start the app for the first time you need to set the parameter "use_live_data = TRUE", so that 
the latest operational data is downloaded from the mySQL Database
```r
aquanes.report::run_app(
                        use_live_data = TRUE ### if TRUE latest operational data from mySQL DB is used
                        )
``` 

### 5.2) Subsequent usage

If you start the app for a second time (i.e. after having at least once performed step 5.1) and do not 
need up-to-date operational data it is sufficient to run the following code (i.e. with "use_live_data = FALSE"):
```r
aquanes.report::run_app()
``` 
