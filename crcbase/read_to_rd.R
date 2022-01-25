library(glue)
library(ggplot2)
library(data.table)
library(janitor)
library(haven)
library(dplyr)
library(stringr)

project_folder = "K:/CRCbase/CRCprojects/Rutegard_sep2020_1"
out_path = glue("{project_folder}/data/derived")
in_path = glue("{project_folder}/data/original")




# List of datasets --------------------------------------------------------


read_infile <- function(file_pattern, nrows=Inf, lopnrs = NULL) {
  files = list.files(in_path)
  file = files[grepl(file_pattern, files)]
  print(glue("Reading: {file}"))
  if (length(file) != 1) stop("Provide more accurrate regex")

  # haven stuff
  d = read_sas( glue("{in_path}/{file}"), n_max = nrows)
  d = zap_labels(d)
  d = d %>%
    mutate_all(
      .funs = list(
        zap_missing,
        zap_formats,
        zap_widths)
      ) %>%
    mutate_if(
      .predicat = is.character,
      .funs = list(
        zap_empty
        )
    )

  print(glue("nrows: {nrow(d)}"))
  data.table::setDT(d)
  if (!is.null(lopnrs)) {
    print("Filtering on lopnr")
    if (! "lopnr" %in% colnames(d)) {
      print("no lopnr variable in data. Skipping filtering")
      return(d)
    }
    d <- d[lopnr %in% lopnrs]
    print(glue("nrows after filtering: {nrow(d)}"))
  }

  return(d)
}

all_files = list.files(in_path)
all_files = all_files[!grepl("txt", all_files)]
project_rdata = lapply(all_files, function(file_name) {
  read_infile(file_name, lopnrs = NULL)
})
names(project_rdata) <- str_remove_all(all_files, "\\.sas7bdat")

# Add original data
try({project_rdata$scrcr_orig = read_sas("K:/CRCbase/CRCBaSe/Data/Derived/SAS/scrcr_clean.sas7bdat")})
try({project_rdata$study_pop = read_sas("K:/CRCbase/CRCBaSe/Data/Derived/SAS/studypop_patients.sas7bdat")})
save(project_rdata, file = "project_rdata.Rdata")

x = load("project_rdata.Rdata")

