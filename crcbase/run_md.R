
run_rmd <- function(rmd) {
    report_name <- str_remove_all(rmd, "\\.rmd") %>% str_c(glue("_{today()}.html"))
    output_name <- glue("./reports/{report_name}")

    render(
        input = rmd,
        output_file = output_name,
        output_format = "html_document",
        clean = TRUE
    )

    copy_report_to_output <- function(from, to) {
        wd <- getwd()
        if (!grepl("^K:", wd)) {
            print("Not in K folder")
            return(NULL)
        }
        # Move upp two folders to find the Output folder
        # This should always be run
        message(glue("Copying report to: {to}"))
        file.copy(from, to)
    }

    to <- glue("../../output/{report_name}")

    tryCatch(copy_report_to_output(from = output_name, to = to), error = function(e) warning(e))
}