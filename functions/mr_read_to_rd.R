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



# - mr_scrcr_20210607		Data from the quality register SCRCR on colorectal cancer. Years 2008-2016. All ages. a2_optyp2 1-7.
# This data acts as index patient data. Format 1:n on "lopnr" and "lopnr diagdate_scrcr".
# Test scrcr
scrcr = read_infile("mr_scrcr")

# Patienter med CRC-diagnos 2007-2016
range(scrcr$diagyear_scrcr)
scrcr = scrcr[diagyear_scrcr %in% 2007:2016]

# Patienter opererade med anastomoskirurgi (surgery_type = 1-7)
tabyl(scrcr$surgery_type)
scrcr = scrcr[surgery_type %in% 1:7]

# Patienter över 50 år (diagage > 50)
tabyl(scrcr$diagage)
qplot(scrcr$diagage) + geom_vline(xintercept = 50, color = "red", linetype = "dashed")
scrcr[diagage > 50]

# Exclusion criteria


# - mr_cdr_20210607		Cause of death information for all index patients. Format 1:1 on lopnr.


# - mr_scrcr_20210607		Data from the quality register SCRCR on colorectal cancer. Years 2008-2016. All ages. a2_optyp2 1-7.
# This data acts as index patient data. Format 1:n on "lopnr" and "lopnr diagdate_scrcr".

# - mr_cdr_20210607		Cause of death information for all index patients. Format 1:1 on lopnr.

# - mr_lmed_20210607		Information from the prescribed drug register on estrogen use prior to CRC. Format 1:n.

# - mr_bc_20210607		Information from the Swedish cancer register on breast cancer diagnoses prior to CRC. Format 1:n.

# - mr_ooforectomies_20210607	Information from the patient register on ooforectomy surgeries prior to CRC.
# Format 1:2 (8 patients have 2 surgeries).

# - mr_lisa_20210607		LISA information 2006-2016. Year specific variables. Format 1:1 (?).- mr_lmed_20210607		Information from the prescribed drug register on estrogen use prior to CRC. Format 1:n.

# - mr_bc_20210607		Information from the Swedish cancer register on breast cancer diagnoses prior to CRC. Format 1:n.

# - mr_ooforectomies_20210607	Information from the patient register on ooforectomy surgeries prior to CRC.
# Format 1:2 (8 patients have 2 surgeries).

# - mr_lisa_20210607		LISA information 2006-2016. Year specific variables. Format 1:1 (?).
# Format 1:2 (8 patients have 2 surgeries).

# - mr_lisa_20210607		LISA information 2006-2016. Year specific variables. Format 1:1 (?).- mr_lmed_20210607		Information from the prescribed drug register on estrogen use prior to CRC. Format 1:n.

# - mr_bc_20210607		Information from the Swedish cancer register on breast cancer diagnoses prior to CRC. Format 1:n.

# - mr_ooforectomies_20210607	Information from the patient register on ooforectomy surgeries prior to CRC.
# Format 1:2 (8 patients have 2 surgeries).

# - mr_lisa_20210607		LISA information 2006-2016. Year specific variables. Format 1:1 (?).

# - mr_bc_20210607		Information from the Swedish cancer register on breast cancer diagnoses prior to CRC. Format 1:n.

# - mr_ooforectomies_20210607	Information from the patient register on ooforectomy surgeries prior to CRC.
# Format 1:2 (8 patients have 2 surgeries).

# - mr_lisa_20210607		LISA information 2006-2016. Year specific variables. Format 1:1 (?).- mr_lmed_20210607		Information from the prescribed drug register on estrogen use prior to CRC. Format 1:n.

# - mr_bc_20210607		Information from the Swedish cancer register on breast cancer diagnoses prior to CRC. Format 1:n.

# - mr_ooforectomies_20210607	Information from the patient register on ooforectomy surgeries prior to CRC.
# Format 1:2 (8 patients have 2 surgeries).

# - mr_lisa_20210607		LISA information 2006-2016. Year specific variables. Format 1:1 (?).
