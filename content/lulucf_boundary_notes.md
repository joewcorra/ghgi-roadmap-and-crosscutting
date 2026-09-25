# LULUCF sector — cross-sector boundary rules (GHGIA Ch.6)

- **Land representation is the spine:** three databases (NRI non-federal, FIA forest,
  NLCD federal/Alaska) classify the 936 M ha US land base into 36 IPCC land-use/
  land-use-change categories. FIA is authoritative for forest; NRI/NLCD adjusted to match.
- **Managed-land proxy:** only MANAGED land is inventoried (886 of 936 M ha). Managed-land
  designation itself uses PAD-US, USFS TPO (timber), NASS (county grazing), EIA/USGS
  (resource extraction) — i.e., several datasets feed the land base BEFORE any flux calc.
- **Conversions stay in "remaining" where not separable:** drained-organic-soil C and all
  non-CO2 from land-converted-to-forest are folded into Forest Land Remaining Forest Land.
  Forest-fire and grassland-fire non-CO2 cover BOTH remaining + converted (can't separate).
- **Settlement N2O** covers both settlements-remaining + land-converted-to-settlements
  (activity data not separable).
- **HWP** (harvested wood products) reported within Forest Land; tracked here under ffl.
- **Biogenic CO2 from landfills/composting** (Waste) lands here in LULUCF, not Waste.
- **Rice cultivation, cranberry, wet meadows** -> classified out of Wetlands into
  Cropland/Grassland per national circumstances.
- **Agricultural soil N2O from fertilizer on croplands/grasslands** -> Agriculture Ch.5.4,
  NOT here. LULUCF soils = carbon stock change (+ forest/settlement fertilizer N2O only).

# Retrieval-hard inputs flagged this sector

- **DS-USDA-NRI** — proprietary; the single most load-bearing LULUCF input (cropland,
  grassland, settlements, conversions, land base). No open feed. Through 2017 only.
- **DS-DAYCENT-LULUCF** — Tier 3 model output; via EPA 2025 (FOIA); continuity uncertain.
- **DS-NRCS-CEAP** — restricted management survey (DayCent input).
- **DS-OPTIS** — proprietary remote-sensing product (cover crop/tillage).
- **DS-DAYCENT shared with Agriculture** — same model underlies ag soils (Ch.5.4) and
  cropland/grassland soil C here. One dependency, two sectors.

# Clean wins this sector

- **USFS FIA DataMart** (forest, HWP, urban trees) is a real downloadable/API source.
- **NLCD, NOAA C-CAP, MTBS, PAD-US** are open geospatial downloads.
- **NID** (reservoirs) has a public API for flooded-land surface area.

# Coverage note
The land categories were decomposed into "remaining"/"converted" sources plus the
distinct non-CO2 sources (fires, fertilizer N2O, drained soils, flooded land, coastal
wetlands). This is the GHGIA/EPA reporting structure; some leaves (peatlands, land-to-other)
flagged needs_validation pending the GHGIA chapter's exact treatment.
