# Waste sector — cross-sector boundary rules (GHGIA Ch.7)

These determine where emissions/data are *allocated*, and are essential for
ingestion logic so the same activity is not counted twice.

- **Biogenic CO2 from landfills & composting** → reported in LULUCF (Ch.6),
  not Waste. Only CH4 (and composting N2O) are estimated here.
- **Waste Incineration (5C1)** → estimate and data live in **Energy Ch.3.3**
  (waste-to-energy + industrial boilers). The Waste-chapter 5C1 entry is a
  pointer only. Medical-waste and sewage-sludge incineration are assessed as
  insignificant (<500 kt CO2 Eq.) and not estimated.
- **Anaerobic digestion split by facility type:**
  - On-farm digesters → Agriculture Ch.5.2 (Manure Management)
  - Digesters at water resource recovery facilities → Wastewater (5D), this chapter
  - Stand-alone biogas facilities → Anaerobic Digestion (5B2), this chapter
- **Wastewater sludge digestion** (digester primary purpose = treating WW solids)
  → reported under Wastewater (5D), not 5B2.
- **Flooded lands / constructed waterbodies** (not for WW treatment) → LULUCF
  Wetlands (Ch.6.8 / 6.9).

# Recent-year (2024) data-gap flags worth tracking as provenance

- **MSW landfills:** 2024 GHGRP not available at prep time → 2023 reported net
  emissions and derived parameters held constant.
- **Composting:** 2019-2024 tonnage extrapolated from 2018 per-capita ratio x Census population.
- **Anaerobic digestion:** 1990-2015 and 2020-21, 2024 rely on extrapolation/interpolation;
  2024 approximated by averaging 2022-23 survey data.
- **BioCycle State of Garbage** survey (historical MSW activity) is discontinued.
