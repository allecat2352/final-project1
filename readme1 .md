# README — NOAA Storm Events Analysis (Final Course Project)



This project analyzes the U.S. National Oceanic and Atmospheric Administration (NOAA) Storm Events Database for the year 2025. It addresses four research questions about severe weather events, their geographic distribution, seasonality, and impact on public health and the economy.

---

## Files Included

| File | Description |
|------|-------------|
| `NOAA_Storm_Analysis.Rmd` | **Main deliverable.** R Markdown document with full narrative, code, and figures. Knit this to produce the HTML report. |
| `NOAA_Storm_Analysis.R` | Standalone R script with all analysis code (mirrors the .Rmd). |
| `README.md` | This file. |

---

## Data Files Required

Place the following three CSV files in the **same folder** as the .Rmd and .R files (or update `folder_path` in both files to point to wherever you saved them):

```
StormEvents_details-ftp_v1.0_d2025_c20260323.csv
StormEvents_fatalities-ftp_v1.0_d2025_c20260323.csv
StormEvents_locations-ftp_v1.0_d2025_c20260323.csv
```

**Source:** https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles/

---

## How to Run

### Option A — Knit the R Markdown (recommended)

1. Open `NOAA_Storm_Analysis.Rmd` in RStudio.
2. Update `folder_path` on line ~55 to point to your data folder.
3. Click **Knit → Knit to HTML**.
4. The HTML report will appear in the same directory.
5. In the preview window, click **Publish** to upload to RPubs.

### Option B — Run the R script

1. Open `NOAA_Storm_Analysis.R` in RStudio or any R console.
2. Update `folder_path` near the top of the file.
3. Source the entire file or run sections sequentially.

---

## Required R Packages

The following packages are used. The scripts will attempt to auto-install any missing ones:

```r
dplyr, readr, ggplot2, forcats, stringr, tidyr, scales,
knitr, kableExtra, gridExtra, ggrepel, RColorBrewer
```

Install all at once if needed:
```r
install.packages(c("dplyr","readr","ggplot2","forcats","stringr","tidyr",
                   "scales","knitr","kableExtra","gridExtra","ggrepel",
                   "RColorBrewer"))
```

---

## Research Questions Addressed

| # | Question |
|---|----------|
| Q1 | Which event types are most harmful to population health (deaths & injuries)? |
| Q2 | Which event types occur most frequently in which states? |
| Q3 | Which event types are characterized by which months (seasonality)? |
| Q4 | Which event types cause the greatest economic damage (property + crops)? |

---

## Key Findings Summary

- **Tornadoes, Heat, and Flash Floods** are the deadliest event types.
- **Texas, Oklahoma, and Missouri** record the highest storm event counts.
- **May–July** is the peak season for convective weather (Thunderstorm Wind, Hail, Flash Flood).
- **Hurricanes and Storm Surges** generate the greatest per-event economic damage by far.

---

## Notes on Data Processing

- Property and crop damage strings (e.g., "1.5K", "20M", "1B") are parsed into numeric USD values using a custom `parse_damage()` function.
- Total injuries = `INJURIES_DIRECT + INJURIES_INDIRECT`.
- Total deaths = `DEATHS_DIRECT + DEATHS_INDIRECT`.
- All three source files are joined on `EVENT_ID` (left join: details ← locations ← fatalities).
- The joined file is saved as `StormEvents_joined_data.csv`.

---

## Reproducibility

All analysis steps begin from the raw CSV files with no external preprocessing. Setting `echo = TRUE` in the knitr setup chunk ensures all code is visible in the published report.

---

