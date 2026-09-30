# GHGI Project Instructions

This file is the source of truth for conventions, tools, and working practices across all GHG inventory work, in this repository and in every source-category repository. When another document disagrees with this file, this file wins. Report the disagreement so the other document can be corrected.

## What this project is

This repository is part of a spec-driven R pipeline for the U.S. Greenhouse Gas Inventory (GHGI). "Spec-driven" means that domain experts write plain-language methodology narratives, and those narratives define what the code must do. Code is written to follow a specification, never to guess at one. The goal is auditability and institutional resilience: the methods should be documented and reproducible even if any one person leaves.

## How to work with me

- I code exclusively in R. I also use HTML and CSS when a document or app needs them. Do not write Python.
- Work incrementally. Prove a pattern on one source category before scaling it to others, and stop at human-review checkpoints instead of pushing ahead.
- Fail loudly, not silently. If an input is missing, a unit is unrecognized, or a methodology step is ambiguous, raise an error or ask me. Do not guess or fill in a plausible value.
- Keep the methodology specification and the code separate. If the code disagrees with the narrative (for example, code that uses an older model version than the narrative cites), report the difference to me. Do not quietly reconcile it, because the difference is useful information.
- I will correct direction mid-conversation. Fold those corrections into everything that follows.
- Write in full sentences. Spell out acronyms the first time they appear, and define technical terms briefly where they are introduced. Avoid symbolic shorthand in prose. Inside code and code comments, normal programming notation is fine.
- Be concise by default, and expand when I ask.

## Repository structure

- `ghgi-roadmap-and-crosscutting` (this repository) is the coordination hub. It holds the schema registry, methodology narratives, cross-cutting design decisions, and this file. It does not pull, transform, or calculate emissions data.
- Each sector has its own source-category repository: `ghg-energy`, `ghg-ippu`, `ghg-agriculture`, `ghg-lulucf`, and `ghg-waste`. Each one handles data pulling, transformation, aggregation, calculation, and visualization for its sector.
- There is no shared `ghg-core` repository. The source-category hierarchy, the dataset registry, and their crosswalk live in this repository's `schema/` folder.
- `syrinx` is the internal helper package (see Tools and packages).

Each source-category repository follows this layout:

```
ghg-[sector]/
├── README.md             Sector overview and quick start
├── METHODOLOGY.md        Methodology documentation
├── data/
│   ├── reference/        Emission factors and lookup tables
│   ├── activity/         Processed activity data
│   └── calculated/       Results, date-stamped
├── data-raw/             Original downloads (git-ignored)
├── R/
│   ├── 01_download.R     Data acquisition
│   ├── 02_clean.R        Cleaning and harmonization
│   ├── 03_calculate.R    Emission calculations
│   ├── 04_validate.R     Quality assurance and quality control checks
│   └── functions/        Helper functions
├── tests/testthat/       Unit tests
├── outputs/              Generated reports and figures
├── docs/                 Data dictionaries and changelog
├── .github/workflows/    GitHub Actions
├── renv.lock
└── _targets.R            Optional; see Tools and packages
```

Data files follow the file-format rule under Tools and packages.

## R coding conventions

### Functions and naming

- Name data-retrieval functions `get_[scope]_[source]_[gas]()`. This applies to emissions data retrieval only; schema and metadata functions (for example, loading or validating the category/dataset registry) are named descriptively instead, such as `read_ghgi_schema()` and `validate_ghgi_schema()`.
- Function names describe the output, not the process: `get_`, not `calculate_`.
- Name intermediate emissions objects with the Common Reporting Table (CRT) row letter, for example `f1_ch4_emissions`.
- Write one function per logical calculation phase. Each function takes named data-frame arguments plus, where needed, a named constants vector, and returns a single tibble with an explicit `return()`. The one exception is a category-level function, which returns a list (see Organizing a category).
- Functions have no side effects: they do not write files, print, or modify global state.
- Helpers shared between national-level and state-level compilation live in a common script. Helpers specific to one level stay in that level's script. Name helpers descriptively in snake_case; an `h_` prefix is optional and only distinguishes a helper from a `get_` function.

### Organizing a category

- Organize each category as a named list built with `tibble::lst()`, holding one tibble per subcategory. For example, electric power generation holds `gas_combustion`, `coal_combustion`, and so on.
- Compute each subcategory in its own function, so the code for one subcategory is easy to find, debug, and change without touching the others.
- The category-level function returns the list with an explicit `return()`:

```r
get_[scope]_[category] <- function(...) {
  gas_combustion  <- get_[scope]_[gas_subcategory]_[gas](...)
  coal_combustion <- get_[scope]_[coal_subcategory]_[gas](...)
  return(lst(gas_combustion, coal_combustion))
}
```

### Style

- Use the magrittr pipe `%>%`, not the native pipe `|>`.
- Use the tidyverse style. Avoid nested `if`/`else`. Prefer `switch()`, named-vector lookups, `dplyr::case_when()`, guard clauses with early returns, and `match.arg()`. Vectorized `ifelse()` and `dplyr::if_else()` are fine.
- Give every `case_when()` a `.default` clause. Use `if_else()` for binary logic. When a branch depends on a value computed earlier in the same `mutate()`, split the work into sequential `mutate()` calls.
- Iterate with `{purrr}` (`map()`, `map_dfr()`, `map2()`, `walk()`). Do not use `for` loops or the `apply()`, `lapply()`, and `sapply()` family.
- Extract columns with `pull()`, not `$`.
- Use snake_case for variable names. Character data is lowercase, with no punctuation except hyphens.

### Data shape and columns

- Keep time series in long format. Never pivot to wide format inside a calculation function.
- Year columns are factors. Apply `forcats::as_factor(year)` whenever a year column is created, for example when scaffolding a series with `tibble(year = start:end)`.
- Do not put unit suffixes in column names (`waste_composted`, not `waste_composted_kt`). Unit context belongs in the data dictionary.
- Name emission columns `[gas]_emissions` (for example `co2_emissions`) and carbon dioxide equivalent columns `[gas]_co2e`.

### Joins, grouping, and output

- Attach treatment tables with an inline `left_join()`, then `filter()`, then `select()`.
- Every join specifies `by` explicitly.
- Follow every `group_by()` with `summarize(..., .groups = "drop")`.
- Build collated results with `tibble()` followed by `pull()`.
- End each script with a section headed `## Output`, which holds the final output block.

### Gap-filling and period splits

Fill gaps with `lag()` and `lead()` inside sequential `mutate()` calls. Handle methodology breaks between periods with `case_when()` on a year threshold:

```r
mutate(value = if_else(
  is.na(value),
  lag(value, 1) + ((lead(value, 1) - lag(value, 1)) / 2),
  value))

mutate(value = case_when(
  year <= [threshold_year] ~ [method_a_expression],
  .default = [method_b_expression]))
```

### Constants

- Pass emission factors, global warming potentials, and other parameters as a single named numeric vector, and reference values by name (`constants["c_content_rubber"]`), never as bare numbers.
- Unit conversions never live in the constants vector or inside a `get_` function. See Unit discipline.

## Unit discipline

- Convert every input to the project's canonical units at ingestion.
- Keep all intermediate calculations unitless.
- Convert units only at the final output step, using named constants (for example, gigagrams to teragrams).
- Constants that carry units, such as emission factors, must declare their native unit basis and be converted to canonical units at ingestion.
- Species-conversion ratios, such as 44 divided by 12 for carbon to carbon dioxide, do not change with scale. Treat them differently from emission factors, which do depend on scale.
- `{units}` is an ingestion-layer tool only. It is never used inside a calculation function.

## Architecture principles

- The meta-module (the layer holding the narratives and the schema) is a control plane. It should produce and constrain the pipeline, not merely accompany it.
- Two decisions must come early: the uncertainty convention must be settled before ingestion is built, and the emissions store schema should be frozen sooner than it feels necessary.
- Data quality is enforced by validation checks at ingestion and at output.

## Tools and packages

- Pipeline orchestration: `{targets}` and `{tarchetypes}` are optional for now; whether to adopt them is an open decision (see Open decisions in `agent/architecture.qmd`). Write every calculation function so it could become a `{targets}` step without rewriting: inputs passed as arguments, no side effects, and one returned tibble (or, for a category-level function, one list of tibbles).
- Versioned data storage: `{pins}`.
- File formats: Parquet through `{arrow}`. Ingestion provenance goes in `_metadata.yml`.
- Data dictionaries: one `data-dict.yaml` file per documented table, hand-authored against the tidyverse `data-dict.yaml` specification. Each column gets its type, constraints, and a `range`, `examples`, or `values` entry verified against the real data. Files are checked by hand with `{yaml}`; do not install the specification's companion command-line tool.
- Validation: `{pointblank}` for data checks at ingestion and output, and `{testthat}` for unit tests of calculation functions.
- Internal helper package: `{syrinx}` (from `joewcorra/syrinx`). It provides `pre_clean()`, `use_dictionary()`, `apply_metadata_labels()`, `to_canonical()`, `to_canonical_all()`, and the `canonical_units` tibble. Use these instead of writing new cleaning or unit-conversion code. Call `pre_clean()` at the end of a function's pipeline whenever its output will be passed downstream or stored. Install it as needed with `remotes::install_github("joewcorra/syrinx")`, adding `auth_token = Sys.getenv("GITHUB_PAT")` if the repository is private.
- Data manipulation: the tidyverse (`{dplyr}`, `{tidyr}`, `{purrr}`, `{readr}`, `{stringr}`, `{forcats}`, `{lubridate}`, `{tibble}`), `{janitor}` (many of its functions are wrapped in `{syrinx}`), `{labelled}`, `{readxl}` and `{openxlsx}` for Excel files, `{jsonlite}`, `{httr2}` for APIs, `{rvest}` for scraping, `{here}` for paths, and `{furrr}` for parallel iteration.
- Spatial data (mainly LULUCF): `{sf}`, `{terra}`, and `{mapview}`.
- Reporting: `{gt}` (with `{gtExtras}`) for tables and `{ggplot2}` (with `{patchwork}`, `{scales}`, and `{showtext}`) for figures. `{visNetwork}` can diagram pipeline dependencies. Documentation is written in Quarto, rendered to HTML, and published to GitHub Pages; diagrams use Mermaid.
- Documentation assistance through direct large language model API calls: `{ellmer}`.
- Package reproducibility: `{renv}`. Each repository has its own `renv.lock`; run `renv::restore()` to reproduce it.

## Custom AI tools

- Custom skills for this project live in `~/.claude/skills/`, outside this repository. Use them when they apply: `ghg-methodology-parser`, `r-ghg-coder`, `r-methodology-narrator`, and `r-data-dict-builder`.
- The typical flow for one source category: the parser turns chapter text into an implementation framework, the coder turns the framework into an R script, and the narrator turns the script back into a plain-language narrative for review by the source lead. The data-dictionary builder runs independently against any table, most usefully once a function's output is stable.
- Each skill's `SKILL.md` must agree with this file. When a convention changes, update this file first, then the affected `SKILL.md`.

## Project management

- Cross-cutting issues and the roadmap live in the `ghgi-roadmap-and-crosscutting` repository. Source-category repositories hold category-specific issues. Work across all repositories is tracked on the single GitHub Project board named "ghgi".
- Board columns: Backlog, Ready, In Progress, Review, Done, and Blocked.
- Cross-repository issue labels: `sector:` (for example `sector:energy`), `priority:` (high, medium, low), `type:` (bug, feature, documentation), and `status:` (blocked, ready-for-review).
- GitHub Actions run `{testthat}` on push and render the documentation site to GitHub Pages.

## Decision authority

Ask the owner of a decision rather than making it:

- The data system developer decides R package choices, code organization, Git workflow details, and development tools.
- Collaborative decisions: data storage and databases, major workflow changes, data access and sharing policies, and public-facing features.
- Sector leads decide sector-specific methodology, data source selection, quality assurance and quality control thresholds, and reporting priorities.

## Reference sources

- The GHGIA Full Report 2026 (University of Maryland Center for Global Sustainability) is the canonical source for units and methodology.
- Use the Intergovernmental Panel on Climate Change Fifth Assessment Report (AR5) global warming potentials.
- Secondary references: the [2006 IPCC Guidelines for National Greenhouse Gas Inventories](https://www.ipcc-nggip.iges.or.jp/public/2006gl/) for emission factor tiers and calculation approaches, the [EPA inventory reports and annexes](https://www.epa.gov/ghgemissions/inventory-us-greenhouse-gas-emissions-and-sinks), and the United Nations Framework Convention on Climate Change reporting requirements for the Common Reporting Tables.

## Writing about this project

- Avoid wording that implies criticism of colleagues or of earlier workflows. For example, say a legacy Excel process is "less efficient," not "clunky."
- For general audiences, say "custom AI tools" rather than "Claude Skills," and emphasize that the tools follow a human-designed specification.

## Where to find more detail

- Design principles and the repository map: `agent/architecture.qmd`.
- Terms and abbreviations: `agent/glossary.qmd`.
- Which sector reports each emission: `content/cross_sector_boundaries.qmd`.
- Source categories, datasets, and their crosswalk: `schema/`, loaded and validated by `R/ghgi_schema.R`.
- Methodology narratives: `content/ghg_inventory_methodology.qmd`.
- Open decisions, review milestones, and criteria for adding complexity: `agent/architecture.qmd`.
