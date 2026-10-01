# GHG Inventory System — Roadmap and Crosscutting

A Quarto website and data schema for the U.S. Greenhouse Gas Inventory and Analysis (GHGIA) system proposal.

## Role in the overall system

This repository is the coordination hub for the GHGI pipeline: the schema registry, methodology narratives, and cross-cutting design decisions. It does not itself pull, transform, or calculate emissions data. Each source category (for example, Waste, Energy, IPPU) has its own separate repository for that category's data pulling, transformation, aggregation, calculation, and visualization. Source-category repositories depend on the schema and methodology defined here, and on shared internal packages such as `{syrinx}`, installed as needed. Work across all repositories is tracked on the "ghgi" GitHub Project board.

## Rendering 

```
quarto render
```

Output goes to `docs/`. The site includes the main proposal, inventory methodology, and cross-sector boundary rules.

## Repository layout

```
_quarto.yml                  Quarto website configuration

content/
  ghg_proposal.qmd             Main system proposal
  ghg_inventory_methodology.qmd  GHG inventory methodology document
  sample_smn_wastewater.qmd    Example Structure Methodology Narrative
  cross_sector_boundaries.qmd  Cross-sector boundary rules (which sector reports each emission)

schema/
  ghgi_categories.csv        Inventory source categories (node hierarchy, CRT codes, gases)
  ghgi_datasets.csv          Dataset registry (provider, access method, endpoint, status)
  ghgi_category_datasets.csv Category–dataset crosswalk (which datasets each source needs)

R/
  ghgi_schema.R               R interface: load, validate, and query the schema files

agent/
  AGENTS.MD                   Working conventions and instructions for AI-assisted development
  architecture.qmd             Design principles, repository map, and data flow
  glossary.qmd                 Project terms and abbreviations
```

## Schema

The three CSV files form a relational schema. `ghgi_schema.R` loads and validates them and provides convenience functions for common queries (datasets needed by a source, shared dataset usage, retrieval plan, etc.). The default `read_ghgi_schema()` call expects the CSVs in `schema/`.

## R environment

Dependencies are managed with `renv`. Run `renv::restore()` to install the locked package versions.
