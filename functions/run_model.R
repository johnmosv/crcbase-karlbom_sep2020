
format_fit <- function(fit, dec = 2) {
    #' tidy up the fit object. Can handle both regular and mixed models
    tidy_function <- broom::tidy
    if (class(fit)[1] == "glmerMod") {
        tidy_fit <- broom.mixed::tidy
    }
    tidy_fit <- tidy_function(fit, exponentiate = TRUE, conf.int = TRUE)
    tidy_fit <- select(tidy_fit, term, estimate, conf.low, conf.high, p.value)
    if (!is.null(dec)) {
        # Remove "NA"
        tidy_fit <- mutate_all(tidy_fit, ~ ifelse(is.na(.), 0, .))
        tidy_fit <- mutate(tidy_fit, p.value = format(round(p.value, digits = dec + 1), nsmall = dec))
        tidy_fit <- tidy_fit %>% mutate_if(is.numeric, ~ format(round(., digits = dec), digits = dec, nsmall = dec))
    }
    return(tidy_fit)
}


count_outcomes_and_denominators <- function(data, outcome, exposure) {
    #' exposure, outcome, n_outcome, N

    count_table <- data[, .N, by = c(outcome, exposure)]
    count_table <- setorderv(count_table, outcome)
    count_table <- dcast(count_table, as.formula(glue("{exposure} ~ {outcome}")), value.var = "N")
    colnames(count_table) <- c("exposure", "outcome_0", "n_outcome")
    # replace the values in the exposure variable with the actual exposure name (al etc) and exposure_name=0
    binary <- all(as.numeric(pull(count_table[, 1])) %in% 0:1)
    if (binary) {
        # the order is 0,1
        count_table$exposure <- paste0(exposure, c("_0", ""))
    }
    count_table[, N := outcome_0 + n_outcome]
    count_table$outcome_0 <- NULL
    count_table$outcome <- outcome
    count_table[, prop := scales::percent(n_outcome / N)]
    count_table <- count_table[, .(exposure, outcome, n_outcome, N, prop)]

    return(count_table)
}
# outcome3 <- "al"
# exposure3 <- "woman"
# count_outcomes_and_denominators(outcome3, exposure3)


run_model <- function(data, outcome, exposure, fixed_covariates,
                      scale_vars = NULL, random_effect = NULL,
                      print_as_table_dt = TRUE,
                      print_model_summary = FALSE) {

    #' Runs the model, tidies up the results, counts the exposures and exposure group sizes
    #' as well as creates a results_table with, n, N, or, cil, ciu, p.value
    #' runs a regular gml if random_effet=NULL, else a glmer from lme4 is run
    #' If random effects is empty, a regular glm will be used


    covariates <- paste(fixed_covariates, collapse = " + ")
    formula_string <- glue("{outcome} ~ {exposure} + {covariates}")
    model_function <- glm
    model_type <- "glm"
    if (!is.null(random_effect)) {
        print("Mixed model")
        formula_string <- glue("{formula_string} + {random_effect}")
        if (!is.null(scale_vars)) {
            for (scale_var in scale_vars) {
                new_name <- paste0(scale_var, "_scaled")
                formula_string <- stringr::str_replace(formula_string, scale_var, new_name)
            }
        }
        model_type <- "glmm"
        model_function <- lme4::glmer
    }
    formula <- as.formula(formula_string)
    fit <- model_function(
        formula = formula,
        family = binomial(link = "logit"),
        data = data
    )

    if (print_model_summary) {
        print(summary(fit))
    }

    # Tidy with broom
    tidy_fit <- format_fit(fit)

    # only exposure vars
    exposure_or <- filter(tidy_fit, grepl(exposure, term))

    if (sum(grepl(paste("^", exposure, sep = ""), exposure_or$term)) > 1) {
        exposure_or$term <- str_remove(exposure_or$term, paste("^", exposure, sep = ""))
    }
    exposure_or <- rename(exposure_or, exposure = term)

    # Count table
    count_table <- count_outcomes_and_denominators(
        data = data,
        outcome = outcome,
        exposure = exposure
    )

    # Results table with n_exposure, N, or, cil, ciu, p.value for all exposure groups
    results_table <- merge(
        count_table,
        exposure_or,
        by = "exposure",
        all = TRUE
    )
    results_table <- rename(results_table, or = estimate)

    if (print_as_table_dt) {
        table_for_dt <- mutate_all(results_table, as.character)
        table_for_dt[is.na(or), or := "Ref"]
        results_table_dt <- table_dt(table_for_dt,
            caption = glue("{model_type}: {formula_string}"),
            title_row_names = FALSE,
            title_col_names = FALSE
        )
        return(results_table_dt)
    }

    return(results_table)
}