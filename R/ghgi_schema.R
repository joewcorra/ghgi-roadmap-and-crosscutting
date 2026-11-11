## ghgi_schema.R
## Load and query the GHGIA (UMD/CGS, 1990-2024) category/dataset schema.
## System of record: Greenhouse Gas Inventory and Analysis for the United States.
## Designed to slot into a {targets} pipeline; tidyverse-first.
##
## Reads the parquet files built by R/build_schema_parquet.R. Validation
## (unique keys, links between tables, allowed values) is done by the
## data-dict command-line tool against schema/data-dict.yaml during that build,
## so these functions assume a validated schema.

library(tidyverse)
library(arrow)
library(here)

# ---- Load -------------------------------------------------------------------
# mmap = FALSE reads each file fully into memory. Without it, Windows keeps the
# file locked and the build script cannot overwrite it in the same session.

read_ghgi_schema <- function(dir = here("schema", "parquet")) {
  read_table <- function(name) {
    read_parquet(file.path(dir, str_glue("{name}.parquet")), mmap = FALSE)
  }

  schema <- list(
    categories     = read_table("ghgi_categories"),
    datasets       = read_table("ghgi_datasets"),
    crosswalk      = read_table("ghgi_category_datasets"),
    dictionaries   = read_table("ghgi_dictionaries"),
    validation_log = read_table("validation_log")
  )
  return(schema)
}

# ---- Tree and placement -----------------------------------------------------

# The sector (root node) of every node, found by walking parent_id upward.
node_sector <- function(schema) {
  links <- schema$categories %>% select(node_id, parent_id)

  find_root <- function(ids) {
    parents <- tibble(node_id = ids) %>%
      left_join(links, by = "node_id") %>%
      pull(parent_id)
    if (all(is.na(parents))) return(ids)
    find_root(coalesce(parents, ids))
  }

  sectors <- schema$categories %>%
    select(node_id) %>%
    mutate(sector = find_root(node_id))
  return(sectors)
}

# Where each dataset's single copy lives, derived from the crosswalk: the one
# sector that uses it, or "shared" when two or more sectors do. Datasets with
# no crosswalk rows get NA, because their home cannot be known yet.
dataset_home <- function(schema) {
  homes <- schema$crosswalk %>%
    left_join(node_sector(schema), by = "node_id") %>%
    group_by(dataset_id) %>%
    summarize(
      n_sectors = n_distinct(sector),
      sectors = str_flatten(sort(unique(sector)), collapse = ";"),
      .groups = "drop"
    ) %>%
    mutate(home = if_else(n_sectors == 1, sectors, "shared"))

  placement <- schema$datasets %>%
    select(dataset_id, dataset_name) %>%
    left_join(homes, by = "dataset_id")
  return(placement)
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
    left_join(select(dataset_home(schema), dataset_id, home), by = "dataset_id") %>%
    arrange(access_method, home != "shared", dataset_id) %>%
    select(access_method, dataset_id, dataset_name, provider, home,
           endpoint, format, auth, access_verified, source_status)
}

# ---- Example usage ----------------------------------------------------------
# Rebuild and validate first: source(here::here("R", "build_schema_parquet.R"))
# schema <- read_ghgi_schema()
# datasets_for(schema, "composting")
# shared_dataset_usage(schema)
# dataset_home(schema)       # which repository holds each dataset's one copy
# unmapped_sources(schema)   # gap list to fill via ghg-methodology-parser
# at_risk_sources(schema)    # categories leaning on now-uncertain federal data
