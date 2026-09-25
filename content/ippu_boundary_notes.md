# IPPU sector — cross-sector boundary rules (GHGIA Ch.4)

- **Combustion energy at industrial facilities** (cement kilns, lime kilns, glass furnaces, etc.)
  -> Energy Ch.3 (industrial end-use). IPPU captures only PROCESS/byproduct emissions.
- **Energy->IPPU fuel reallocation:** portions of 7 fuel categories (coking coal, distillate,
  industrial other coal, petroleum coke, natural gas, residual fuel oil, other oil) are
  reallocated FROM Energy combustion TO IPPU because consumed as feedstock/reducing agent.
  >>> This is exactly Joe's ippu_dist_* + ippu_corrections targets in _targets.R. <<<
  Sources: ammonia, petrochemical, carbon black, iron & steel, aluminum, TiO2, zinc.
- **Non-energy use of fossil fuels** (lubricants, waxes, asphalt, solvents) -> reported in
  Energy Ch.3.2, NOT IPPU 2D, due to US carbon-balance national circumstances.
- **Lime for agricultural use (LKD/soil)** -> Agriculture Ch.5.5 (Liming, 3G).
- **Limestone/soda ash consumed IN glass** -> reported under Glass (2A3), not Other Carbonates.
- **FGD limestone/lime at power plants** -> Other Process Uses of Carbonates (2A4).
- **Biogenic CO2 from regenerated lime** (Kraft pulp mills, water treatment) -> LULUCF, not IPPU.
- **Soda ash CO2 captured for PCC/sugar refining** -> netted out (no net emissions).

# Data-architecture notes for retrieval

- GHGRP is the dominant IPPU activity-data source (most categories). Many values are
  AGGREGATED CBI (ammonia, nitric acid, lime, cement, petrochemical, CO2 consumption, urea).
  >>> All GHGRP-dependent IPPU categories inherit source_status = uncertain. <<<
- USGS National Minerals Information Center: per-commodity files for minerals + metals.
- Industry associations (AISI, ACC, AHRI, TFI, USAA, NLA) are membership/manual sources,
  not clean APIs — flag for manual retrieval.
- ODS Substitutes (largest IPPU source) is driven by the EPA VINTAGING MODEL, a bottom-up
  stock model — not a downloadable dataset. Output continuity is uncertain post-EPA.
- CARB SF6 data informs the non-reporter emission factor for electrical equipment.

# Reconciliation flag (vs Joe's Energy code)
The four ippu_dist_* targets (ammonia, petrochemical, carbon_black, iron_and_steel) in
_targets.R are the Energy-side half of this reallocation. The IPPU chapter is the
receiving side. Worth a future end-to-end trace to confirm the reallocation reconciles.
