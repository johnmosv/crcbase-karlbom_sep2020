define_tumour_side <- function(col_location) {
    print("tumour_side: (col_location in 0-5 right, 6-8 left, 9 undefined")
    dplyr::case_when(
        col_location %in% 0:5 ~ "right",
        col_location %in% 5:8 ~ "left",
        col_location == 8 ~ "undefined",
        TRUE ~ as.character(NA)
    )
}

define_tumour_location <- function(location) {
    print("tumour_side: location == 0 -> 'colon', location == 1 -> 'rectum'")
    dplyr::case_when(
        location == 0 ~ "colon",
        location == 1 ~ "rektum",
        TRUE ~ as.character(NA)
    )
}

process_scrcr = function(indata) {
    scrcr = indata

    # female
    print("sex ==2 -> 'female'")
    scrcr[, female := ifelse(sex == 2, 1, 0)]
    
    # BMI
    heigth_min <- 120
    heigth_max <- 220
    weight_min <- 40
    weight_max <- 200
    wh_ratio_flip_limit = 2
    print("BMI fixes:")
    
    # Fix ratio
    print(glue("weight / height ratio over {wh_ratio_flip_limit} are flipped "))
    scrcr[, wh_ratio := weight / height]
    scrcr[wh_ratio >= wh_ratio_flip_limit, `:=`(height_new = weight, weight_new = height)]
    scrcr[wh_ratio >= wh_ratio_flip_limit, `:=`(height = height_new, weight = weight_new)]
    scrcr$weight_new <- NULL
    scrcr$height_new <- NULL
    # Clean unrealistic values
    print(glue("Heigh between {heigth_min}-{heigth_max} and weight between {weight_min} and {weight_max} allowed"))
    scrcr[height < heigth_min | height > heigth_max, height := NA]
    scrcr[weight < weight_min | weight > weight_max, weight := NA]
    scrcr[, bmi := weight / (height / 100)^2]

    scrcr[, tumour_side := define_tumour_side(col_location)]
    scrcr[, tumour_location := defined_tumour_location(location)]
    

    return(scrcr)
}