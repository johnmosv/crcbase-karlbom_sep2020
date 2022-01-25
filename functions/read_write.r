
source("crcbase/crcbase_read_and_write.R")

project_path = create_project_path("Karlbom_sep2020")

# This is where all the `cleaned` files, like migration, ipr, scrcr_clean, end up for the project
read_from_project_original = create_read_from_project_subfolder("data/original", project_path=project_path())
write_to_project_original = create_write_to_project_subfolder("data/original", project_path=project_path())

# This is where all of the derived datasets end up (usually just the analysis_data)
write_to_project_derived = create_write_to_project_subfolder("data/derived", project_path=project_path())