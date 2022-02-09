# Most of the data is created in SAS-scrips made by Caroline W.
# This script only add migrations for the population
source(glue::glue("{utils_root_dir}/crud/setup_project_crud.R"))
source(glue::glue("{utils_root_dir}/crud/crcbase_read_and_write.R"))

scrcr <- read_from_project_original("uk_scrcr_20220207.sas7bdat")
setDT(scrcr)
pop_exp <- scrcr[, .(diagdate_scrcr_first = min(diagdate_scrcr)), by = "lopnr"]
# Add comparators to scrcr to create population

# Strata contains the lopnr for the case
comp <- read_only_from_crcbase_derived_csv("studypop_comparators.csv", sep = ",", dec = ".")
comp <- comp[strata %in% pop_exp$lopnr]
comp$case <- "unexposed"
comp_1 <- comp[, .(lopnr, strata, case, indexdate)]
colnames(comp_1)[colnames(comp_1) == "indexdate"] <- "diagdate_scrcr"
comp_1$diagdate_scrcr <- lubridate::as_date(comp_1$diagdate_scrcr, origin = "1960-01-01")

exp <- data.table(lopnr = pop_exp$lopnr, strata = pop_epx$lopnr, case = "exposed", diagdate_scrcr = pop_exp$diagdate_scrcr)

studypopulation <- rbindlist(list(exp, comp_1))
write_to_project_original(studypopulation, "studypopulation.csv")




# Get the population that was just written. In case you only want to run this section ----
pop <- read_from_project_original("studypopulation.csv")


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