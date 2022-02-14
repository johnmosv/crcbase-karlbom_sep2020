# Most of the data is created in SAS-scrips made by Caroline W.
# This script only add migrations for the population
source(glue::glue("{utils_root_dir}/crud/setup_project_crud.R"))
source(glue::glue("{utils_root_dir}/crud/crcbase_read_and_write.R"))
source(glue::glue("{utils_root_dir}/crud/read_data.R"))

scrcr <- read_from_project_original("uk_scrcr_20220207.sas7bdat")
setDT(scrcr)
pop_exp <- scrcr[, .(diagdate_scrcr_first = min(diagdate_scrcr)), by = "lopnr"]
# Add comparators to scrcr to create population

studypopulation <- read_studypopulation(lopnrs = pop_exp$lopnr)
# Add matchdate and diagdate to both. Join matchdate from
write_to_project_original(studypopulation, "studypopulation.csv")




# Get the population that was just written. In case you only want to run this section ----
pop <- read_from_project_original("studypopulation.csv")


# SBO surgeries directly from ipr (not used) ----
# all sbo surgeries. Not just the ones before. dont have index date available here.
ipr_clean <- read_only_from_crcbase_derived_csv("ipr_clean.csv", sep = ",", dec = ".", lopnr = source_pop$lopnr)
ipr <- ipr_clean %>% select(lopnr, indate, hdia, dia1:dia30, surgerycodes)

# find the relevant codes (op)
# patterns for operations. Should allow optional leading whitespace
sbo_op_pattern1 <- definitions$procedure_codes[["sbo_operation_alt1"]] %>% str_c(collapse = "| ?")
sbo_op_pattern2 <- definitions$procedure_codes[["sbo_operation_alt2"]] %>% str_c(collapse = "| ?")

ipr[, `:=`(
    sbo_op1 = str_detect(surgerycodes, sbo_op_pattern1),
    sbo_op2 = str_detect(surgerycodes, sbo_op_pattern2)
)]
ipr[, .(sum(sbo_op1), sum(sbo_op2))]
sbo_surgeries <- ipr[sbo_op1 == 1 | sbo_op2 == 2]
nrow(sbo_surgeries)


# Find rows with ileus icd code
ileus_pattern <- definitions$icd_codes$ileus %>% str_c(collapse = "|")

# looks through all the dia columns and returns a vector with one value per row indicating if any ileus icds are present
sbo_surgeries$ileus_dia <- find_pattern_in_columns(select(sbo_surgeries, contains("dia")), ileus_pattern)
sbo_surgeries_dias <- sbo_surgeries1[ileus_dia == TRUE]
nrow(sbo_surgeries_dias)
sbo_surgeries_dias[, .(
    nrow = .N,
    sum(sbo_op1),
    sum(sbo_op2),
    sum(sbo_op1 == 1 | sbo_op1 == 1)
)]


# Migrations ---------
# type 1 = immigration
# type 2 = emmmigration
migrations <- read_only_from_crcbase_derived_sas("migrations_clean.sas7bdat", lopnrs = pop$lopnr, zap_sas = FALSE)
migrations[, migration_type := ifelse(type == 2, "emmigration", "imigration")]
migrations <- migrations[migrationdate >= diagdate_scrcr]
write_to_project_original(migrations, "uk_migrations_20220207.sas7bdat")


# Create all previous abdominal surgery ( any procedurecode that starts with prior to diagdate_scrcr j)
ipr <- read_only_from_crcbase_derived_csv("ipr_clean.csv", lopnrs = pop$lopnr, selected_vars = c("lopnr", "indate", "surgerycodes"), sep = ",", dec = ".")
# Add diagdate_scrcr
ipr_date <- merge(ipr, pop[!duplicated(lopnr), .(lopnr, diagdate_scrcr)], all.x = FALSE, all.y = FALSE, by = "lopnr")
ipr_prior <- ipr_date[indate < diagdate_scrcr]

previous_abd_surgeries <- ipr_prior[surgerycodes %like% "^J| J"]
write_to_project_original(previous_abd_surgeries, "uk_previous_abd_surgeries_20220207.csv")