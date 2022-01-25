library(data.table)
source("project_functions/read_write.R")


# Get the population ---- 
scrcr = read_from_project_original("uk_scrcr_20210609.sas7bdat")
setDT(scrcr)
pop = scrcr[,.(diagdate_scrcr_first = min(diagdate_scrcr)), by = "lopnr"]
nrow(pop)


# Migrations ---------
# type 1 = immigration
# type 2 = emmmigration
migrations = read_only_from_crcbase_derived("migrations_clean.sas7bdat", lopnrs = pop$lopnr, zap_sas=FALSE)
migrations[, migration_type := ifelse(type == 2, "emmigration", "imigration")]
migrations = merge(
    pop,
    migrations, 
    by = "lopnr",
    all.x = FALSE, all.y = TRUE
)

migrations = migrations[migrationdate >= diagdate_scrcr_first]
write_to_project_original(migrations, "uk_migrations_20211210.sas7bdat")



