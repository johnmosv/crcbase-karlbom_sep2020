source("crcbase/helpers.R")

fix_scrcr_dubletter <- function(scrcr, first_tumour_only = TRUE) {
    if (!is.data.table(scrcr)) setDT(scrcr)
    setkey(scrcr, lopnr, diagdate_scrcr)

    print(glue("Input dataframe has {nrow(scrcr)} rows with {length(unique(scrcr$lopnr))} unique lopnr"))

    # 1. kompletta dubletter
    complete_duplicates <- duplicated(scrcr) # this is causing the c stack overflow

    perc_complete_duplicates <- scales::percent(mean(complete_duplicates))
    print(glue("removing {sum(complete_duplicates)} complete duplicates ({perc_complete_duplicates})"))
    scrcr_clean <- scrcr[!complete_duplicates]

    # 2. dubletter lopnr, diagdate
    # a. Låt säga att du vill ha allas första tumör.
    # Välj allas första datum.
    if (first_tumour_only) {
        print("Keeping first tumour only (syncronous included)")
        scrcr_clean[, first_diagdate := min(diagdate_scrcr, na.rm = TRUE), by = "lopnr"] # nolint
        is_first_date <- scrcr_clean$diagdate_scrcr == scrcr_clean$first_diagdate
        print(glue("Removing {sum(!is_first_date)} rows ({percent(mean(!is_first_date))}) by only selecting the first tumour only"))
        scrcr_clean <- scrcr_clean[is_first_date]
        n_duplicated_lopnr <- length(unique(scrcr_clean[duplicated(lopnr)]$lopnr))
        print(glue("Still {n_duplicated_lopnr} lopnr with duplicated tumours on the same date (syncronous tunours)"))
        scrcr_clean[, first_diagdate := NULL]
    }


    # b. Bland dubletterna på dessa;
    # sortera dubletterna så att du får med så mkt info som
    # möjligt (=nedprioritera missing)

    # proportion rowwise missing for
    scrcr_multiple_first_tumours <- scrcr_clean[duplicated_all(lopnr)]
    scrcr_single_tumour <- scrcr_clean[!lopnr %in% unique(scrcr_multiple_first_tumours$lopnr)]
    rowwise_missing <- apply(scrcr_multiple_first_tumours, 1, function(variable) mean(is.na(variable)))

    # Control the missingness for the first row
    if (rowwise_missing[1] != mean(is.na(scrcr_multiple_first_tumours[1]))) {
        stop("the rowssise_missing does not equal the missing from the first row")
    }
    # Add rowwise_missing after to be able to compare the rowwise_miggins to the first rows missing
    # proportion directly (above if clause)
    scrcr_multiple_first_tumours$rowwise_missing <- rowwise_missing

    # Create n_first_tumours for the individuals with multiple
    scrcr_multiple_first_tumours[, n_first_tumours := .N, by = c("lopnr", "diagdate_scrcr")]

    # ”välja” den rad med högst pTNM-stadium/stadium
    # (sort by first has pTNM stadiumn)
    # Variables called pt, pn, pm (as in pathological )
    # TNM staging system:
    # Tumor (T):
    # Node (N):
    # Metastasis (M):
    # create a sum of pTNM
    scrcr_multiple_first_tumours[, ptnm_sum := pt + pn + pm]

    # Special case for MR1. Want to keep the tumour witht he highest risk of AL
    print("Keep the tumour with the highest risk of AL (rektum>colon and left>right")
    scrcr_multiple_first_tumours[, `:=`(
        col_location_priority = dplyr::case_when(
            col_location %in% 1:5 ~ "2. right",
            col_location %in% 6:8 ~ "1. left",
            col_location == 9 ~ "3. undefined",
            TRUE ~ "4. missing"
        ),
        location_priority = dplyr::case_when(
            location == 1 ~ "2. colon",
            location == 2 ~ "1. rektum",
            TRUE ~ "3. missing"
        )
    )]


    # Sort correctly and keep the first row. The one mist the highest
    # pTNM and least missing
    print("Sorting by (1)al risk (rektum>colon, left>right), (2) sum(pTNM) and (3)rowwise missing proportion. Keeping the row with the highest sum(pTNM) followed by row wise missing when removing duplicates")
    setorder(
        scrcr_multiple_first_tumours,
        lopnr, diagdate_scrcr,
        location_priority, # rektum > colon rektum will stay on top and missing last
        col_location_priority, # left > right > undefined > missing
        ptnm_sum,
        rowwise_missing
    )
    scrcr_multiple_first_tumours_removed <- duplicated(scrcr_multiple_first_tumours$lopnr)
    n_multiple_first_tumours_removed <- sum(scrcr_multiple_first_tumours_removed)
    print(glue("Removing {n_multiple_first_tumours_removed} rows with multiple first tumours.
        Keeping the row with the least missing information and pTNM stage from SCRCR"))

    # Put the single tumour rows and multiple tumour rows back together
    scrcr_multiple_tumour_selected <- scrcr_multiple_first_tumours[!duplicated(lopnr)]
    scrcr_clean2 <- bind_rows(
        scrcr_single_tumour,
        scrcr_multiple_tumour_selected
    )

    # Remove helping variables. Only keeping n_first_tumours
    # which is missing for single first tumour patients.
    scrcr_clean2[, `:=`(
        ptnm_sum = NULL
    )]

    print(glue("Returning {nrow(scrcr_clean2)} rows, with {length(unique(scrcr_clean2$lopnr))} unique lopnr"))

    return(scrcr_clean2)
}

# fix_scrcr_dubletter(scrcr)