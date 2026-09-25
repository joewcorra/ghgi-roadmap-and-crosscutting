## ghgi_schema.R
## Load and validate the GHGIA (UMD/CGS, 1990-2024) category/dataset schema.
## System of record: Greenhouse Gas Inventory and Analysis for the United States.
## Designed to slot into a {targets} pipeline; tidyverse-first.

library(tidyverse)

# ---- Load -------------------------------------------------------------------

read_ghgi_schema <- function(dir = "schema") {
  list(
    categories = read_csv(file.path(dir, "ghgi_categories.csv"),
                          show_col_types = FALSE),
    datasets   = read_csv(file.path(dir, "ghgi_datasets.csv"),
                          show_col_types = FALSE),
    crosswalk  = read_csv(file.path(dir, "ghgi_category_datasets.csv"),
                          show_col_types = FALSE)
  )
}

# ---- Referential integrity --------------------------------------------------
# node_id is the unique key; crt_code is the official reporting code and is
# intentionally NON-unique (e.g. coal_mining and abandoned_coal_mines share 1B1a).

validate_ghgi_schema <- function(schema) {
  node_ids <- schema$categories$node_id
  ds_ids   <- schema$datasets$dataset_id

  dup_nodes    <- node_ids[duplicated(node_ids)]
  orphan_nodes <- setdiff(schema$crosswalk$node_id, node_ids)
  orphan_ds    <- setdiff(schema$crosswalk$dataset_id, ds_ids)
  bad_parents  <- schema$categories %>%
    filter(!is.na(parent_id), !parent_id %in% node_ids) %>%
    pull(node_id)

  stopifnot(
    "node_id is not unique"                       = length(dup_nodes)    == 0,
    "crosswalk references unknown node_id"        = length(orphan_nodes) == 0,
    "crosswalk references unknown dataset_id"     = length(orphan_ds)    == 0,
    "category has unknown parent_id"              = length(bad_parents)  == 0
  )
  invisible(schema)
}

# ---- Convenience views ------------------------------------------------------

# Every dataset a given source needs, with full metadata.
datasets_for <- function(schema, node_id) {
  schema$crosswalk %>%
    filter(node_id == !!node_id) %>%
    left_join(schema$datasets, by = "dataset_id")
}

# Shared datasets ranked by how many sources depend on them (registry payoff).
shared_dataset_usage <- function(schema) {
  schema$crosswalk %>%
    count(dataset_id, name = "n_sources") %>%
    left_join(schema$datasets, by = "dataset_id") %>%
    arrange(desc(n_sources))
}

# Sources whose datasets are not yet mapped: the worklist to feed the parser.
unmapped_sources <- function(schema) {
  schema$categories %>%
    filter(level %in% c("source", "subsource", "category")) %>%
    anti_join(schema$crosswalk, by = "node_id") %>%
    select(node_id, crt_code, source_name, chapter, needs_validation)
}

# Sources exposed to data-availability risk (e.g. GHGRP continuity).
at_risk_sources <- function(schema) {
  schema$crosswalk %>%
    left_join(schema$datasets, by = "dataset_id") %>%
    filter(source_status != "available") %>%
    left_join(select(schema$categories, node_id, source_name), by = "node_id") %>%
    select(node_id, source_name, dataset_id, dataset_name, source_status)
}

# Coding worklist: datasets grouped by how they're fetched. Build one retrieval
# function per access_method, then map over the rows. `access_verified == FALSE`
# flags endpoints to confirm before relying on them.
retrieval_plan <- function(schema) {
  schema$datasets %>%
    arrange(access_method, desc(shared), dataset_id) %>%
    select(access_method, dataset_id, dataset_name, provider,
           endpoint, format, auth, access_verified, source_status)
}

# ---- Example usage ----------------------------------------------------------
# schema <- read_ghgi_schema() |> validate_ghgi_schema()
# datasets_for(schema, "composting")
# shared_dataset_usage(schema)
# unmapped_sources(schema)   # gap list to fill via ghg-methodology-parser
# at_risk_sources(schema)    # categories leaning on now-uncertain federal data

