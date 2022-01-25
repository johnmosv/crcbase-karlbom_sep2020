colorize <- function(x, color = "red") {
    if (knitr::is_latex_output()) {
        sprintf("\\textcolor{%s}{%s}", color, x)
    } else if (knitr::is_html_output()) {
        sprintf("<span style='color: %s;'>%s</span>", color, x)
    } else {
        x
    }
}

rename_columns <- function(data) {
    cn <- colnames(data)
    cn <- stringr::str_to_lower(cn)
    cn <- stringr::str_replace_all(cn, "å", "a")
    cn <- stringr::str_replace_all(cn, "ä", "a")
    cn <- stringr::str_replace_all(cn, "ö", "o")
    cn <- stringr::str_replace_all(cn, " ", "_")
    cn <- stringr::str_replace_all(cn, "[-]+", "_")

    colnames(data) <- cn

    return(data)
}

find_variable <- function(var_pattern, ignore_case = TRUE, dfs = list(
                              bc = bc,
                              cci = cci,
                              cdr = cdr,
                              list = lisa,
                              lmed = lmed,
                              ooforectomies = ooforectomies,
                              scrcr = scrcr
                          )) {
    lapply(dfs, function(d) {
        cn <- colnames(d)
        # ignore case
        if (ignore_case) {
            cn <- stringr::str_to_lower(cn)
            var_pattern <- stringr::str_to_lower(var_pattern)
        }
        cn[grepl(var_pattern, cn)]
    })
}

truethy <- function(x) {
    if (is.numeric(x)) {
        x[is.na(x)] <- 0
        if (!all(x %in% 0:1)) stop("none 0,1 values in numeric logical vector")
        return(x == 1)
    }
    if (is.logical(x)) {
        x[is.na(x)] <- FALSE
        return(x)
    }
}



duplicated_all <- function(x) {
    duplicated(x) | rev(duplicated(rev(x)))
}

pcollapse <- function(x, sep = " | ") {
    paste0(x, collapse = sep)
}

split_collapse <- function(x, sep = " | ") {
    unlist(stringr::str_split(x, " \\| "))
}


is_na <- function(x) {
    if (is.character(x)) {
        x[x == ""] <- NA
    }
    is.na(x)
}

left_merge <- function(x, y, id_vars = "lopnr") {
    nrow_x <- nrow(x)
    if (any(duplicated(x$lopnr))) warning("Duplicated in x")
    if (any(duplicated(y$lopnr))) warning("Duplicated in y")

    if (any(colnames(y) %in% colnames(x))) {
        cols_already_in_x <- colnames(y)[colnames(y) %in% colnames(x)]
        # Remove id_vars
        cols_already_in_x <- cols_already_in_x[!cols_already_in_x %in% id_vars]
        cols_already_in_x_concat <- paste0(cols_already_in_x, collapse = ", ")
        if (length(cols_already_in_x) > 0) {
            warning(glue("Columns {cols_already_in_x_concat} already in x. Removing from y"))
            y <- select(y, -cols_already_in_x)
        }
    }

    d <- merge(x, y, by = id_vars, all.x = T)
    if (nrow(d) > nrow_x) {
        stop("Added rows in left merge. Please use merge instead if you want to add rows")
    }

    return(d)
}


# With added with
table_dt <- function(data, col_names = NULL, first_colname = NULL, title_row_names = TRUE, title_col_names = TRUE, row_groups = FALSE,
                     alignment = "dt-center", align_targets = NULL, page_length = 20, class = NULL, row_callback = NULL, width = NULL, ...) {
    require(DT, quietly = TRUE)
    require(stringr, quietly = TRUE)
    require(dplyr, quietly = TRUE)

    data <- ungroup(data)
    dom_settings <- "tB"

    if (is.null(col_names)) {
        col_names <- colnames(data)
    }

    if (title_col_names) {
        col_names <- str_to_title(str_replace_all(col_names, "_", " "))
    }


    if (row_groups) {
        if (is.factor(data[[1]])) data[[1]] <- as.character(data[[1]])
        data[duplicated(data[, 1]), 1] <- " "
    }

    if (!is.null(first_colname)) col_names[1] <- first_colname

    if (is.null(align_targets)) {
        align_targets <- 1:(ncol(data) - 1)
    }

    if (is.null(class)) {
        class <- "compact stripe"
    }

    if (page_length < nrow(data)) {
        dom_settings <- "tBflp"
    }

    if (is.null(width)) {
        n_col <- ncol(data)
        width <- dplyr::case_when(
            n_col >= 10 ~ 100,
            n_col >= 6 ~ 90,
            n_col >= 4 ~ 80,
            n_col >= 3 ~ 70,
            n_col <= 2 ~ 60,
            TRUE ~ 100
        )
        width <- paste0(width, "%")
    }

    if (title_row_names) data <- mutate_at(data, 1, ~ str_to_title(str_replace_all(., "_", " ")))

    if (is.null(row_callback)) {
        color2 <- "#F6F8FA"
        row_callback <- JS(
            "function(row, data, num, index){",
            "  var $row = $(row);",
            "  if($row.hasClass('even')){",
            "    $row.css('background-color', 'white');",
            "    $row.hover(function(){",
            "      $(this).css('background-color', '#F6F8FA');",
            "     }, function(){",
            "      $(this).css('background-color', 'white');",
            "     }",
            "    );",
            "  }else{",
            "    $row.css('background-color', '#F6F8FA');",
            "    $row.hover(function(){",
            "      $(this).css('background-color', 'gray');",
            "     }, function(){",
            "      $(this).css('background-color', '#F6F8FA');",
            "     }",
            "    );",
            "  }",
            "}"
        )
    }


    return_table <- data %>%
        DT::datatable(
            rownames = FALSE,
            colnames = col_names,
            class = class,
            extensions = "Buttons",
            escape = FALSE,
            editable = TRUE,
            fillContainer = FALSE,
            width = width,
            options = list(
                dom = dom_settings,
                pageLength = page_length,
                columnDefs = list(list(className = alignment, targets = align_targets)),
                scrollX = TRUE,
                scrollCollapse = TRUE,
                buttons = list(list(
                    extend = "collection",
                    buttons = c("csv", "excel", "pdf"),
                    text = "Download"
                )),
                rowCallback = row_callback,
                headerCallback <- JS(
                    "function(thead, data, start, end, display){",
                    "   $('thead').css({'background-color': 'white'});",
                    "   $('thead').css({'font-weight': 'bold'});",
                    # "   $('thead').css({'padding': '10px'});", # not working. need to target thead.th.tr
                    "}"
                ),
                initComplete = JS(
                    "function(settings, json) {",
                    #            "$('table.dataTable.no-footer').css('border-bottom', 'none');",
                    "$('table.dataTable.no-footer').css('border-top', '2px solid black');",
                    "$('table.dataTable.no-footer').css('border-bottom', '2px solid black');",
                    "}"
                )
            ),
            ...
        ) %>%
        formatStyle(columns = 1, color = "black", fontWeight = "bold")

    if (any("p.value" %in% colnames(data))) {
        return_table <- return_table %>%
            formatStyle(columns = "p.value", color = styleInterval(0.05, c("red", "black")))
    }

    # TODO add total
    return(return_table)
}

tabyl_dt <- function(data, var1, var2 = NULL, ...) {
    require(rlang, quietly = TRUE) # for curly curly
    res <- janitor::tabyl(data, {{ var1 }})
    if (!is.null(expr({{ var2 }}))) {
        res <- tabyl(data, {{ var1 }}, {{ var2 }})
    }

    if (knitr::is_html_output()) {
        return_table <- table_dt(res, , title_row_names = FALSE, title_col_names = FALSE, ...)

        percent_cols <- c("percent", "valid_percent")
        percent_cols_present <- percent_cols %in% colnames(res)
        if (any(percent_cols_present)) {
            percent_cols <- percent_cols[percent_cols_present]
            return_table <- return_table %>% DT::formatPercentage(columns = "percent")
        }
        return(return_table)
    }

    return(DT::datatable(res))
}

# tabyl_dt(iris, Sepal.Length)


transpose_dt <- function(table1) {
    # Good for transposing aggregated dt to table_dt
    row_names_dt <- data.table(names = colnames(table1))
    table_trans <- data.table::transpose(table1)
    table_trans <- cbind(row_names_dt, table_trans)
    colnames(table_trans) <- as.character(table_trans[1])
    table_trans <- table_trans[-1]
    return(table_trans)
}


n_per <- function(x, remove_na = FALSE) {
    # Remove na or set them to false
    if (is.numeric(x)) {
        # TODO make sure it is binary
        valid_values <- c(NA, 1, 0)
        unique_values <- unique(x)
        if (any(!unique_values %in% valid_values)) {
            stop(glue("This is not a binary variable. Contains: {pcollapse(unique_values)}"))
        }
        x <- x == 1
    }

    if (!is.logical(x)) {
        stop("x must be logical or binary numeric variable (1/0)")
    }

    # Handle NA
    if (remove_na) {
        print(glue("removing missing from variable {scales::percent(mean(is.na(x)))}"))
        x <- x[!is.na(x)]
    } else {
        # Set the missing to FALSE
        x[is.na(x)] <- FALSE
    }

    # Calculate prop and n
    count <- sum(x)
    prop <- mean(x)
    perc <- scales::percent(prop)

    res <- glue("{count} ({perc})")

    return(res)
}

mean_sd <- function(x, remove_na = TRUE, digits = 1) {
    if (!is.numeric(x)) stop("x must be numeric")
    m <- format(round(mean(x, na.rm = remove_na), digits = digits), nsmall = digits)
    sdev <- format(round(sd(x, na.rm = remove_na), digits = digits), nsmall = digits)
    m_sd <- glue("{m} ({sdev})")
    return(m_sd)
}
# mean_sd(1:10, digits = 3)

median_iqr <- function(x, remove_na = TRUE, digits = 1) {
    if (!is.numeric(x)) stop("x must be numeric")
    m <- format(round(median(x, na.rm = remove_na), digits = digits), nsmall = digits)
    quant_025_075 <- format(round(quantile(x, na.rm = remove_na, probs = c(0.25, 0.75)), digits = digits), nsmall = digits)
    m_iqr <- glue("{m} ({quant_025_075[1]}-{quant_025_075[2]})")
    return(m_iqr)
}
# median_iqr(1:10)

