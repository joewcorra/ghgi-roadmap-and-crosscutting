# Agriculture sector — cross-sector boundary rules (GHGIA Ch.5)

- **On-farm energy use:** CO2 (stationary + mobile) and stationary CH4/N2O → Energy Ch.3;
  mobile on-farm CH4/N2O → Energy mobile combustion. Not in Agriculture.
- **Land-use & conversion fluxes** (cropland cultivation, grassland management,
  grassland fires, aquaculture, forest→cropland) → LULUCF Ch.6. Not in Agriculture.
- **Unmanaged manure N2O** (pasture/range/paddock deposition by grazing livestock)
  → reported under Agricultural Soil Management (3D), NOT Manure Management (3B).
- **Anaerobic digesters:** on-farm → Manure Management (3B); stand-alone biogas → Waste 5B2;
  WRRF digesters → Waste 5D.
- **Urea for non-agricultural use** → IPPU Ch.4.
- **Liming minerals used in industrial processes** (cement, glass) → IPPU Ch.4.

# Retrieval-hard inputs flagged this sector (not simple API pulls)

- **DS-USDA-NRI** — proprietary; underlies DayCent. No open feed.
- **DS-DAYCENT-OUTPUT** — model output; only via EPA 2025 (FOIA); continuity uncertain.
- **DS-IFA-FERTILIZER** — IFASTAT; membership-gated for full series.
- **DS-BURNED-AREA** — EPA-derived 6-state analysis, extrapolated; no clean public feed.

# Clean wins this sector

- **USDA NASS QuickStats API** covers enteric, manure, rice, soils-surrogate, and FBAR
  activity data through one endpoint — highest-leverage fetcher to build.
- **PRISM** (precipitation) and **USGS crushed stone** are straightforward downloads.
