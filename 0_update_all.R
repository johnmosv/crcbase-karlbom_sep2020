source("crcbase_utils/process/run_rmd.R")

run_create_original_data <- function() {
    source("1_create_original_data.R")
}

run_create_analysisdata <- function() {
    run_rmd("2_create_analysisdata.rmd")
}

run_create_results <- function() {
    run_rmd("3_create_results.rmd") 
}

update_all <- function() {
    run_create_original_data()
    run_create_analysisdata()
    run_create_results()
}