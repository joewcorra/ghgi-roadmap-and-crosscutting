## dashboard_data.R
## Data functions for the read-only dataset status dashboard.
##
## Each function takes its inputs as arguments, has no side effects, and
## returns one tibble, so any of them can become a {targets} step later
## without rewriting. Nothing here writes to the schema, to a pins board, or
## to any other store: the dashboard only reads.
##
## Requires the schema helpers in R/ghgi_schema.R (read_ghgi_schema(),
## dataset_home()).

library(tidyverse)
library(pins)

# ---- Schema integrity -------------------------------------------------------

# Every foreign key in the schema: a child column whose values must exist in
# a parent column. Mirrors the relationships in schema/data-dict.yaml.
schema_link_table <- function() {
  links <- tribble(
    ~child,           ~child_col,          ~parent,        ~parent_col,
    "categories",     "parent_id",         "categories",   "node_id",
    "categories",     "canonical_dict_id", "dictionaries", "dict_id",
    "crosswalk",      "node_id",           "categories",   "node_id",
    "crosswalk",      "dataset_id",        "datasets",     "dataset_id",
    "validation_log", "dataset_id",        "datasets",     "dataset_id",
    "datasets",       "dict_id",           "dictionaries", "dict_id"
  )
  return(links)
}

# Child keys that have no matching parent row, for one link.
find_orphan_keys <- function(schema, child, child_col, parent, parent_col) {
  child_keys  <- pull(schema[[child]], child_col)
  parent_keys <- pull(schema[[parent]], parent_col)

  orphans <- tibble(key = unique(child_keys)) %>%
    filter(!is.na(key), !key %in% parent_keys) %>%
    mutate(link = str_c(child, ".", child_col, " -> ", parent, ".", parent_col)) %>%
    select(link, key)
  return(orphans)
}

# Stops with a list of every broken link. The data-dict tool checks the same
# relationships when the Parquet files are built; checking again here catches
# Parquet files that are out of date with the CSV files. Returns the (empty)
# table of orphans when the schema is sound.
check_schema_links <- function(schema, links = schema_link_table()) {
  orphans <- links %>%
    pmap_dfr(function(child, child_col, parent, parent_col) {
      find_orphan_keys(schema, child, child_col, parent, parent_col)
    })

  if (nrow(orphans) > 0) {
    detail <- orphans %>%
      mutate(line = str_c("  ", link, ": ", key)) %>%
      pull(line) %>%
      str_flatten(collapse = "\n")
    stop(
      "The schema has keys with no matching parent row. Fix the CSV files ",
      "in schema/ and rebuild with R/build_schema_parquet.R.\n", detail,
      call. = FALSE
    )
  }
  return(orphans)
}

# ---- Pin status -------------------------------------------------------------

# The status row for a pin that is not on its board. Called with a
# zero-length name, it gives an empty table with the right columns.
absent_pin_status <- function(pin_name) {
  absent <- tibble(
    pin_name,
    pin_exists        = FALSE,
    pin_first_created = as.POSIXct(NA),
    pin_last_created  = as.POSIXct(NA),
    pin_versions      = 0L,
    pin_user_meta     = list(NULL)
  )
  return(absent)
}

# What one board knows about one pin: whether it exists, when its first and
# latest versions were written, how many versions it has, and any metadata
# stored with pin_write(metadata = ...). A missing pin is a normal state, not
# an error.
get_pin_status <- function(board, pin_name) {
  if (!pin_exists(board, pin_name)) return(absent_pin_status(pin_name))

  meta     <- pin_meta(board, pin_name)
  versions <- pin_versions(board, pin_name)

  status <- tibble(
    pin_name,
    pin_exists        = TRUE,
    pin_first_created = min(pull(versions, created)),
    pin_last_created  = meta$created,
    pin_versions      = nrow(versions),
    pin_user_meta     = list(meta$user)
  )
  return(status)
}

# One row per dataset and pin type (raw, cleaned), with the board each pin
# should live on and what that board reports. `boards` is a named list of
# pins boards keyed by the homes dataset_home() returns (a sector name or
# "shared"); every home in use must have a board.
#
# pin_state values:
#   no pin stem     the dataset has no pin_stem yet, so no pin name exists
#   no home         no crosswalk row, so dataset_home() cannot place it
#   not yet pinned  the pin name is known but the board does not have it
#   pinned          the board has the pin
get_dataset_pin_dates <- function(schema, boards, pin_types = c("raw", "cleaned")) {
  homes <- dataset_home(schema) %>%
    select(dataset_id, home)

  missing_boards <- homes %>%
    filter(!is.na(home), !home %in% names(boards)) %>%
    distinct(home) %>%
    pull(home)
  if (length(missing_boards) > 0) {
    stop(
      "No pins board was supplied for: ",
      str_flatten(missing_boards, collapse = ", "), ".",
      call. = FALSE
    )
  }

  expected <- schema$datasets %>%
    select(dataset_id, dataset_name, provider, access_method, pin_stem) %>%
    left_join(homes, by = "dataset_id") %>%
    cross_join(tibble(pin_type = pin_types)) %>%
    mutate(pin_name = str_c(pin_stem, "_", pin_type))

  lookable <- expected %>%
    filter(!is.na(pin_name), !is.na(home))

  found <- map2_dfr(
    pull(lookable, home),
    pull(lookable, pin_name),
    function(home, pin_name) get_pin_status(boards[[home]], pin_name)
  ) %>%
    bind_rows(absent_pin_status(character()), .)

  pin_dates <- expected %>%
    left_join(found, by = "pin_name", na_matches = "never") %>%
    mutate(pin_state = case_when(
      is.na(pin_stem) ~ "no pin stem",
      is.na(home)     ~ "no home",
      pin_exists      ~ "pinned",
      .default        = "not yet pinned"
    ))
  return(pin_dates)
}

# ---- Display tables ---------------------------------------------------------

# One row per dataset with the raw and cleaned pin side by side, for the
# dashboard table. The pivot to wide format is for display only; the pin
# data itself stays long.
get_pin_date_table <- function(pin_dates) {
  display <- pin_dates %>%
    select(dataset_id, dataset_name, provider, access_method, home,
           pin_stem, pin_type, pin_state, pin_last_created) %>%
    pivot_wider(
      names_from  = pin_type,
      values_from = c(pin_state, pin_last_created),
      names_glue  = "{pin_type}_{.value}"
    ) %>%
    arrange(dataset_id)
  return(display)
}

# ---- Stage ------------------------------------------------------------------

# The retrieval stages in order. A dataset's stage is the furthest it has
# reached.
retrieval_stage_levels <- function() {
  return(c("identified", "access confirmed", "raw pinned", "cleaned pinned"))
}

# Expected months between provider releases, for each update_frequency value.
# NA means no fixed schedule, so the dataset is never flagged as overdue.
# "2-3 yearly" uses the longer interval so it is not flagged early.
refresh_month_table <- function() {
  refresh <- tribble(
    ~update_frequency, ~refresh_months,
    "monthly",          1,
    "annual",           12,
    "biennial",         24,
    "2-3 yearly",       36,
    "5-yearly",         60,
    "periodic",         NA,
    "static",           NA,
    "historical",       NA,
    "discontinued",     NA
  )
  return(refresh)
}

# The categories that use each dataset, from the crosswalk: a count and a
# semicolon-separated list of names (for filtering and display).
get_dataset_categories <- function(schema) {
  categories <- schema$crosswalk %>%
    left_join(select(schema$categories, node_id, source_name), by = "node_id") %>%
    group_by(dataset_id) %>%
    summarize(
      n_categories = n_distinct(node_id),
      categories   = str_flatten(sort(unique(source_name)), collapse = "; "),
      .groups = "drop"
    )
  return(categories)
}

# One row per dataset with every status the dashboard shows, all derived from
# existing schema columns and the pins boards; nothing is stored.
#
#   retrieval_stage  identified, access confirmed, raw pinned, cleaned pinned
#   dict_status      the dictionaries table's dict_status, or "none"
#   calc_use         "used" when validation_log lists a pipeline target,
#                    "not used" when it lists none, "not logged" with no row
#   drift_status     validation_log's drift_status, or "not logged"
#   overdue_status   "overdue" when more months have passed since the latest
#                    cleaned pin than update_frequency allows; otherwise
#                    "current", "not pinned", or "no schedule"
#
# `pin_table` is the output of get_pin_date_table(). `as_of` is the date to
# measure overdue status against.
get_dataset_stage <- function(schema, pin_table, as_of) {
  unknown_frequency <- schema$datasets %>%
    anti_join(refresh_month_table(), by = "update_frequency") %>%
    distinct(update_frequency) %>%
    pull(update_frequency)
  if (length(unknown_frequency) > 0) {
    stop(
      "update_frequency values with no refresh interval in ",
      "refresh_month_table(): ", str_flatten(unknown_frequency, collapse = ", "),
      call. = FALSE
    )
  }

  stages <- pin_table %>%
    left_join(
      select(schema$datasets, dataset_id, update_frequency, access_verified, dict_id),
      by = "dataset_id"
    ) %>%
    left_join(select(schema$dictionaries, dict_id, dict_status), by = "dict_id") %>%
    left_join(
      select(schema$validation_log, dataset_id, pipeline_target, drift_status),
      by = "dataset_id"
    ) %>%
    left_join(refresh_month_table(), by = "update_frequency") %>%
    left_join(get_dataset_categories(schema), by = "dataset_id") %>%
    mutate(
      raw_pinned     = raw_pin_state == "pinned",
      cleaned_pinned = cleaned_pin_state == "pinned",
      has_target     = map_lgl(pipeline_target, function(x) any(!is.na(x))),
      months_since_cleaned = time_length(
        interval(as_date(cleaned_pin_last_created), as_of), "months"
      )
    ) %>%
    mutate(
      retrieval_stage = case_when(
        cleaned_pinned  ~ "cleaned pinned",
        raw_pinned      ~ "raw pinned",
        access_verified ~ "access confirmed",
        .default        = "identified"
      ) %>%
        factor(levels = retrieval_stage_levels()),
      dict_status = coalesce(dict_status, "none"),
      calc_use = case_when(
        is.na(drift_status) ~ "not logged",
        has_target          ~ "used",
        .default            = "not used"
      ),
      drift_status = coalesce(drift_status, "not logged"),
      overdue_status = case_when(
        is.na(refresh_months)                  ~ "no schedule",
        !cleaned_pinned                        ~ "not pinned",
        months_since_cleaned > refresh_months  ~ "overdue",
        .default                               = "current"
      ),
      n_categories = coalesce(n_categories, 0L)
    ) %>%
    select(dataset_id, dataset_name, provider, access_method, home,
           n_categories, categories, retrieval_stage, cleaned_pin_state,
           raw_pin_last_created, cleaned_pin_last_created, dict_status,
           calc_use, drift_status, update_frequency, overdue_status)
  return(stages)
}

# ---- Coverage ---------------------------------------------------------------

# One row per category-dataset pair in the crosswalk, with the dataset's
# retrieval stage. A pair listed under more than one role is collapsed to one
# row: its roles are joined with semicolons, and it counts as required if
# any of its roles is required. Datasets with no crosswalk rows do not appear.
get_coverage_grid <- function(schema, stages) {
  grid <- schema$crosswalk %>%
    group_by(node_id, dataset_id) %>%
    summarize(
      role     = str_flatten(sort(unique(role)), collapse = "; "),
      required = any(required),
      .groups = "drop"
    ) %>%
    left_join(node_sector(schema), by = "node_id") %>%
    left_join(select(schema$categories, node_id, source_name), by = "node_id") %>%
    left_join(
      select(stages, dataset_id, dataset_name, home, retrieval_stage),
      by = "dataset_id"
    ) %>%
    arrange(sector, source_name, home, dataset_id)
  return(grid)
}

# ---- Dependencies -----------------------------------------------------------

# One row per dataset summarizing what depends on it: how many categories and
# sectors use it, and in how many of those it is required. Sorted so the most
# widely used datasets come first. Datasets with no crosswalk rows are kept,
# with zero counts.
get_dataset_dependency_summary <- function(coverage, stages) {
  usage <- coverage %>%
    group_by(dataset_id) %>%
    summarize(
      n_categories = n_distinct(node_id),
      n_sectors    = n_distinct(sector),
      n_required   = sum(required),
      .groups = "drop"
    )

  summary <- stages %>%
    select(dataset_id, dataset_name, provider, home, retrieval_stage) %>%
    left_join(usage, by = "dataset_id") %>%
    mutate(across(c(n_categories, n_sectors, n_required), function(x) coalesce(x, 0L))) %>%
    arrange(desc(n_categories), dataset_id)
  return(summary)
}

# Number of datasets at each retrieval stage, including stages with none.
get_stage_counts <- function(stages) {
  counts <- stages %>%
    count(retrieval_stage, .drop = FALSE)
  return(counts)
}
