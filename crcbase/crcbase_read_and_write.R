require(haven)
require(stringr)
require(glue)
require(dplyr)
require(data.table)


read_sas_and_format <- function(path, nrows = Inf, zap_sas=TRUE) {
    if (!is.infinite(nrows)) {
        warning(glue("Only reading {nrows} rows"))
    }
    d = read_sas(path, n_max = nrows)
    if (!zap_sas) {
        print("Not zapping sas file")
        return(d)
    }
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
    setDT(d)
    print(glue("Read: {nrow(d)} rows | {ncol(d)} columns"))
    return(d)
}

create_project_path = function(project_namex) {

    project_path_function = function(project_name=project_namex, normalize=FALSE) {
        all_projects_folder = "K:/CRCbase/CRCprojects"
        project_path = glue("{all_projects_folder}/{project_name}")
        if (normalize) {
             project_path = normalizePath(project_path)
        }
        return(project_path)
    }

    return(project_path_function)
}
project_path = create_project_path("Karlbom_sep2020")
project_path()

create_read_from_project_subfolder <- function(project_subfolder, project_path) {
    #` Used to create folder specific read function in a project
    #` Example read_from_derived = create_read_from_project_folder("data/derived", "project_name")
    #` data = read_from_derived("scrcr_clean.sas7bdat")

    full_path = glue("{project_path}/{project_subfolder}")

    read_function = function(file_name, full_project_folder_path=full_path, nrows=Inf, zap_sas=TRUE) {

        full_file_path = glue("{full_project_folder_path}/{file_name}")
        full_file_path = normalizePath(full_file_path)

        if (file.exists(full_file_path)) {
            print(glue("Reading file from: {full_file_path}"))
            is_sas_file = grepl("sas7bdat", full_file_path)
            if (is_sas_file) {
                print("...as sas file...")
                return(read_sas_and_format(full_file_path, nrows = nrows, zap_sas=zap_sas))
            }
            print("... as .csv...")
            dt = data.table::fread(full_file_path, nrows=nrows)
            print("Read: {nrow(dt)} rows | {ncol(dt)} columns")
        }
        
        files = list.files(full_project_folder_path)
        if (length(files) == 0) {
            print("No files in folder")
            return(NULL)
        }
        print(glue("Cannot find file. Do you mean:\n{paste0(files, collapse = '\n')}"))
    }

    return(read_function)
}
# read_from_original_folder = create_read_from_project_subfolder(project_subfolder = "data/original", project_path = project_path())
# x = read_from_original_folder("uk_scrcr_20210609.sas7bdat", nrows=10)

create_write_to_project_subfolder = function(subfolder, project_path) {

    full_path = glue("{project_path}/{subfolder}")
    write_function = function(x, file_name, full_project_folder_path = full_path) {
        full_file_path = glue("{full_project_folder_path}/{file_name}")
        print(glue("Writing file to: {full_file_path}"))
        if (grepl("sas7bdat", file_name)) {
            haven::write_sas(x, full_file_path)
        } else {
        data.table::fwrite(x, full_file_path)
        }
    }
    return(write_function)
}
# write_to_project_derived = create_write_to_project_subfolder("data/derived", project_path())
# write_to_project_derived(iris, "iris.csv")

read_only_from_crcbase_derived = function(sas_file_name, lopnrs = NULL, nrows = Inf, zap_sas=TRUE) {

    # This is the absolute path with all the dervied sas files
    # This path should be used for read only
    crcbase_derived_path = "K:/CRCbase/CRCBaSe/Data/Derived/SAS"

    full_path = glue("{crcbase_derived_path}/{sas_file_name}")
    normalized_path = normalizePath(full_path)

    if (file.exists(normalized_path)) {

        print(glue("File found: {sas_file_name}. Reading...."))
        d = read_sas_and_format(normalized_path, nrows=nrows, zap_sas = zap_sas)
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

    # File not found
    print("asdasd")
    sas_files = list.files(crcbase_derived_path, pattern = "sas7bdat")
    print(glue("Cannot find file: {sas_file_name}. Do you mean any of:\n{paste0(sas_files, collapse = '\n')}"))
    
}

# read_only_from_crcbase_derived("scrcr_clean.sas7bdat", nrows = 10)
# read_only_from_crcbase_derived("non.existing.file")
