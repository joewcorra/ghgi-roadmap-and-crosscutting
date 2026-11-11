## build_schema_parquet.R
## Converts the hand-edited GHGI schema CSV files to parquet and validates
## them against schema/data-dict.yaml with the data-dict command-line tool
## (pinned to v0.0.3), then renders the dictionary as a browsable page at
## docs/schema-dictionary.html. The CSV files stay the copy you edit; the
## parquet files and the page are build products. Run from anywhere inside
## the project.

library(tidyverse)
library(arrow)
library(here)

# ---- Settings ----

schema_dir  <- here("schema")
parquet_dir <- here("schema", "parquet")
dictionary_page <- here("docs", "schema-dictionary.html")

# ---- Column specifications ----
# Explicit types so an all-empty column is still read as text, not logical.
# List columns are read as text here and split on ";" below.

schema_tables <- list(
  ghgi_categories = list(
    col_types = cols(
      node_id = col_character(),
      level = col_character(),
      parent_id = col_character(),
      crt_code = col_character(),
      source_name = col_character(),
      gases = col_character(),
      chapter = col_double(),
      needs_validation = col_logical(),
      canonical_dict_id = col_character()
    ),
    list_cols = c("crt_code", "gases")
  ),
  ghgi_datasets = list(
    col_types = cols(
      dataset_id = col_character(),
      dataset_name = col_character(),
      provider = col_character(),
      role_default = col_character(),
      access_method = col_character(),
      endpoint = col_character(),
      format = col_character(),
      auth = col_character(),
      update_frequency = col_character(),
      source_status = col_character(),
      access_verified = col_logical(),
      notes = col_character(),
      dict_id = col_character(),
      pin_stem = col_character()
    ),
    list_cols = c("format")
  ),
  ghgi_category_datasets = list(
    col_types = cols(
      node_id = col_character(),
      dataset_id = col_character(),
      role = col_character(),
      required = col_logical(),
      provenance = col_character(),
      notes = col_character()
    ),
    list_cols = character()
  ),
  ghgi_dictionaries = list(
    col_types = cols(
      dict_id = col_character(),
      dict_path = col_character(),
      tier = col_character(),
      dict_status = col_character(),
      description = col_character()
    ),
    list_cols = character()
  ),
  validation_log = list(
    col_types = cols(
      dataset_id = col_character(),
      source_layer = col_character(),
      pipeline_target = col_character(),
      drift_status = col_character(),
      note = col_character()
    ),
    list_cols = c("pipeline_target")
  )
)

# ---- Helpers ----

# Split semicolon-separated text into a list column. Missing values become
# empty lists. The explicit element type keeps a zero-row table's list column
# typed as text in parquet rather than inferred as numeric.
split_semicolons <- function(x) {
  x %>%
    str_split(fixed(";")) %>%
    map(~ discard(str_trim(.x), function(part) is.na(part) | part == "")) %>%
    vctrs::as_list_of(.ptype = character())
}

# Read one schema CSV file and return it as a tibble with list columns.
# Fails loudly if the CSV's columns do not match the specification exactly.
read_schema_csv <- function(spec, table_name) {
  path <- file.path(schema_dir, str_glue("{table_name}.csv"))
  expected <- names(spec$col_types$cols)
  found <- names(read_csv(path, n_max = 0, show_col_types = FALSE))

  if (!setequal(found, expected)) {
    stop(str_glue(
      "{table_name}.csv columns do not match the specification.\n",
      "  Missing: {str_flatten_comma(setdiff(expected, found))}\n",
      "  Unexpected: {str_flatten_comma(setdiff(found, expected))}"
    ))
  }

  table <- read_csv(path, col_types = spec$col_types, na = "") %>%
    mutate(across(all_of(spec$list_cols), split_semicolons))

  return(table)
}

# Locate the data-dict executable: on the PATH, or in ~/bin, where the
# install instructions put it (Git Bash adds ~/bin to its PATH; RStudio and
# PowerShell do not).
find_data_dict <- function() {
  candidates <- c(
    Sys.which("data-dict"),
    file.path(Sys.getenv("USERPROFILE"), "bin", "data-dict.exe"),
    file.path(Sys.getenv("HOME"), "bin", "data-dict")
  )
  found <- candidates[candidates != "" & file.exists(candidates)]
  if (length(found) == 0) {
    stop("data-dict not found on the PATH or in ~/bin. ",
         "See how-to/maintain-the-schema.qmd to install it.")
  }
  return(found[[1]])
}

# Run one data-dict command. The tool exits with status 1 when any check
# fails.
run_data_dict <- function(step, dict_dir, extra_args = character()) {
  status <- system2(find_data_dict(), c(step, shQuote(dict_dir), extra_args))
  if (status != 0) stop(str_glue("data-dict {step} failed for {dict_dir}"))
}

## Output

dir.create(parquet_dir, showWarnings = FALSE)

schema_parquet <- imap(schema_tables, read_schema_csv)

iwalk(schema_parquet, function(table, table_name) {
  write_parquet(table, file.path(parquet_dir, str_glue("{table_name}.parquet")))
})

walk(c("validate-spec", "validate-meta", "validate-data"),
     run_data_dict, dict_dir = schema_dir)

# Render the browsable dictionary page only after validation passes, so the
# published page never describes data that failed its checks.
run_data_dict("render", schema_dir,
              extra_args = c("-o", shQuote(dictionary_page)))
