# GHG Inventory System — Roadmap and Crosscutting

A Quarto website and data schema for the U.S. Greenhouse Gas Inventory and Analysis (GHGIA) system proposal.

## Rendering the site

```
quarto render
```

Output goes to `docs/`. The site includes the main proposal, inventory methodology, technical reference, and sector-level boundary notes.

## Repository layout

```
_quarto.yml                  Quarto website configuration

content/
  ghg_proposal.qmd             Main system proposal
  ghg_inventory_methodology.qmd  GHG inventory methodology document
  technical_standards_and_tools_reference.qmd
  sample_smn_wastewater.qmd    Example Structure Methodology Narrative
  *_boundary_notes.md          Sector boundary notes (Energy, IPPU, Agriculture, LULUCF, Waste)

schema/
  ghgi_categories.csv        Inventory source categories (node hierarchy, CRT codes, gases)
  ghgi_datasets.csv          Dataset registry (provider, access method, endpoint, status)
  ghgi_category_datasets.csv Category–dataset crosswalk (which datasets each source needs)

R/
  ghgi_schema.R               R interface: load, validate, and query the schema files
```

## Schema

The three CSV files form a relational schema. `ghgi_schema.R` loads and validates them and provides convenience functions for common queries (datasets needed by a source, shared dataset usage, retrieval plan, etc.). The default `read_ghgi_schema()` call expects the CSVs in `schema/`.

## R environment

Dependencies are managed with `renv`. Run `renv::restore()` to install the locked package versions.
