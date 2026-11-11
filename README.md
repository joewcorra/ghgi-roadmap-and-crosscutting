# GHG Inventory System — Roadmap and Crosscutting

The coordination hub for the U.S. Greenhouse Gas Inventory (GHGI) pipeline: the schema registry, methodology narratives, cross-cutting rules, and project conventions that every source-category repository depends on. This repository does not pull, transform, or calculate emissions data. Each source category (for example, Waste, Energy, IPPU) has its own repository for that work.

Conventions for all GHGI work, for people and AI tools alike, are in [`AGENTS.md`](AGENTS.md).

## Repository layout

Documentation is organized by the [Diátaxis](https://diataxis.fr/) framework into how-to guides, reference, and explanation.

```
AGENTS.md          Conventions and working practices; source of truth for all GHGI repositories
CLAUDE.md          Imports AGENTS.md so Claude Code loads it automatically
index.qmd          Map of the documentation

how-to/
  render-the-documents.qmd            Render the Quarto documents to HTML
  maintain-the-schema.qmd             Edit the schema, then rebuild and validate it with data-dict
  query-the-schema.qmd                Load and query the schema in R

reference/
  conventions.qmd                     Displays AGENTS.md
  schema.qmd                          Column-by-column description of the five schema tables
  cross-sector-boundaries.qmd         Cross-sector boundary rules: which sector reports each emission
  glossary.qmd                        Project terms and abbreviations
  methodology/
    ghg-inventory-methodology.qmd     Methodology narrative and coding annotations by source category
    sample-smn-wastewater.qmd         Example methodology narrative (wastewater treatment)

explanation/
  architecture.qmd                    Design principles, open decisions, and review milestones
  sector-data-notes.qmd               Data-availability risks and recent-year gaps by sector

schema/
  ghgi_categories.csv                 Inventory source categories (node hierarchy, CRT codes, gases)
  ghgi_datasets.csv                   Dataset registry (provider, access method, endpoint, status)
  ghgi_category_datasets.csv          Category–dataset crosswalk (which datasets each source needs)
  ghgi_dictionaries.csv               Registry of data dictionaries and their status
  validation_log.csv                  Methodology drift log
  data-dict.yaml                      Data dictionary for the five schema tables
  parquet/                            Generated from the CSVs; do not edit by hand

R/
  build_schema_parquet.R              Build the Parquet files and validate them with data-dict
  ghgi_schema.R                       Load and query the schema

_quarto.yml        Quarto configuration
docs/              Rendered HTML output (generated; do not edit by hand)
```

## Schema and boundary rules

The CSV files in `schema/` form a relational schema: categories and datasets are linked through the crosswalk, and the dictionary registry and drift log hang off the datasets. The CSV files are the copy you edit. `R/build_schema_parquet.R` converts them to Parquet and validates the result against `schema/data-dict.yaml` using the `data-dict` command-line tool (v0.0.3). `R/ghgi_schema.R` loads the Parquet files and provides functions for common queries, such as the datasets a source needs, datasets shared across sources, where each dataset lives, and a retrieval plan grouped by access method.

`reference/cross-sector-boundaries.qmd` states once, for each activity or emission that could fall in more than one sector, which sector reports it, so that no activity is counted twice.

## R environment

Dependencies are managed with `renv`. Run `renv::restore()` to install the locked package versions.
