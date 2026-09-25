# Energy sector — cross-sector boundary rules (GHGIA Ch.3)

- **Combustion vs fugitive:** 1A = combustion (fuel burned for energy). 1B = fugitive
  (leaks/venting/flaring from fuel production/transport, no combustion).
- **Energy->IPPU reallocation:** 7 fuel categories partly reallocated to IPPU as
  feedstock/reducing agent (see ippu_boundary_notes). Joe's ippu_dist_* targets.
- **Non-energy use (3.2)** reported in Energy, NOT IPPU 2D, per US carbon-balance
  national circumstances (lubricants, waxes, asphalt, solvents).
- **Incineration of Waste (3.3)** reported in ENERGY (waste-to-energy + industrial
  boilers), not Waste 5C. Only FOSSIL carbon fraction counts; biogenic -> LULUCF.
- **Bunker fuels + biomass** are MEMO items: reported for transparency, excluded from
  national totals to avoid double counting / per IPCC biogenic treatment.
- **Coal mine CH4 recovery/use** netted: liberated CH4 minus recovered-and-used.
- **CO2 transport/injection (1C)** new category; geologic storage accounting.

# Retrieval-hard / availability-exposed inputs this sector

- **GHGRP Subpart W** (petroleum + gas systems) and **Subpart FF** (coal) and
  **Subpart RR/UU** (CO2 injection): all source_status = uncertain post-EPA.
- **DS-EPA-CMOP** (coalbed methane outreach) + **DS-EPA-MSW-COMBUST**: EPA programs,
  continuity uncertain.
- **DS-ENVERUS-WELLS** — commercial license (Enverus/DrillingInfo). Not open.
- **DS-STATE-WELLS** — heterogeneous state oil/gas commission sources; no single feed;
  hardest abandoned-well activity data to assemble.

# Clean wins this sector

- **EIA Open Data v2** covers coal, natural gas, and petroleum throughput via API
  (shared with the FFC fetcher already built) — reuse the same client.
- **MSHA Mine Data Retrieval System** is a public CSV download.

# Note on FFC (already mapped + code-validated)
fossil_fuel_combustion was mapped earlier and reconciled against Joe's _targets.R.
See dataset_provenance.csv for the code-vs-chapter bridge (FOKS method-drift, MOVES
version-drift, GHGRP-disaggregation structure, state/territory scope).
