# UTILITY FUNCTIONS ----

# 1. Mapping Functions -----

grouped_mapper <- function(data, target, .f, ...) {

    data            <- prep_tbl_time(data, message = F)

    target_expr     <- dplyr::enquo(target)

    group_names     <- dplyr::group_vars(data)

    ret <- data %>%
        dplyr::group_nest() %>%
        dplyr::mutate(nested.col = purrr::map(
            .x           = data,
            .f           = .f,
            target       = !! target_expr,
            ...)
        ) %>%
        dplyr::select(-data) %>%
        tidyr::unnest(cols = nested.col) %>%
        dplyr::group_by_at(.vars = group_names)

    # if (merge) {
    #     ret <- merge_two_tibbles(tib1 = data, tib2 = ret, .f = .f)
    # }

    return(ret)

}

# 2. Merging Time-Based Tibbles -----

merge_two_tibbles <- function(tib1, tib2, .f) {

    # Merge results
    if (identical(nrow(tib1), nrow(tib2))) {

        # Arrange dates - Possibility of issue if dates not decending in tib1
        tib1 <- arrange_by_date(tib1)

        # Drop date column and groups
        tib2 <- drop_date_and_group_cols(tib2)

        # Replace bad names
        tib2 <- replace_bad_names(tib2, .f)

        # Replace duplicate names
        tib2 <- replace_duplicate_colnames(tib1, tib2)

        ret <- dplyr::bind_cols(tib1, tib2)

    } else {

        stop("Could not join. Incompatible structures.")
    }

    return(ret)
}

replace_duplicate_colnames <- function(tib1, tib2) {

    # Collect column names
    name_list_tib1 <- colnames(tib1)
    name_list_tib2 <- colnames(tib2)
    name_list <- c(name_list_tib1, name_list_tib2)

    duplicates_exist <- detect_duplicates(name_list)

    # Iteratively add .1, .2, .3 ... onto end of column names
    if (duplicates_exist) {

        i <- 1

        while (duplicates_exist) {

            dup_names_stripped <-
                strsplit(name_list[duplicated(name_list)],
                                   split = "\\.\\.") %>%
                sapply(function(x) x[[1]])

            name_list[duplicated(name_list)] <-
                paste0(dup_names_stripped, "..", i)

            i <- i + 1

            duplicates_exist <- detect_duplicates(name_list)

        }

        name_list_tib2 <- name_list[(ncol(tib1) + 1):length(name_list)]

        colnames(tib2) <- name_list_tib2
    }

    return(tib2)
}

detect_duplicates <- function(name_list) {

    name_list %>%
        duplicated() %>%
        any()
}

# bad / restricted names are names that get selected unintetionally by OHLC functions
replace_bad_names <- function(tib, fun_name) {

    bad_names_regex <- "open|high|low|close|volume|adjusted|price"

    name_list_tib <- colnames(tib)
    name_list_tib_lower <- tolower(name_list_tib)

    detect_bad_names <- grepl(pattern = bad_names_regex,
                              x       = name_list_tib_lower)

    if (any(detect_bad_names)) {

        len <- length(name_list_tib_lower[detect_bad_names])
        name_list_tib[detect_bad_names] <- rep(fun_name, length.out = len)

    }

    colnames(tib) <- name_list_tib

    return(tib)
}

arrange_by_date <- function(tib) {

    if (dplyr::is.grouped_df(tib)) {

        group_names <- dplyr::group_vars(tib)

        arrange_date <- function(tib) {
            date_col <- timetk::tk_get_timeseries_variables(tib)[[1]]
            tib %>%
                dplyr::arrange(!! rlang::sym(date_col))
        }

        tib <- tib %>%
            tidyr::nest() %>%
            dplyr::mutate(nested.col =
                              purrr::map(data, arrange_date)
            ) %>%
            dplyr::select(-data) %>%
            tidyr::unnest(cols = nested.col) %>%
            dplyr::group_by_at(.vars = group_names)


    } else {
        date_col <- timetk::tk_get_timeseries_variables(tib)[[1]]
        tib <- tib %>%
            dplyr::arrange(!! rlang::sym(date_col))

    }

    return(tib)
}

drop_date_and_group_cols <- function(tib) {

    date_col <- timetk::tk_get_timeseries_variables(tib)[[1]]
    group_cols <- dplyr::groups(tib) %>%
        as.character()
    cols_to_remove <- c(date_col, group_cols)
    tib_names <- colnames(tib)
    cols_to_remove_logical <- tib_names %in% cols_to_remove
    tib_names_without_date_or_group <- tib_names[!cols_to_remove_logical]

    tib <- tib %>%
        dplyr::ungroup() %>%
        dplyr::select(!!! rlang::syms(tib_names_without_date_or_group))

    return(tib)
}
