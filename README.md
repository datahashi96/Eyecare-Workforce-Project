# Eye Care Workforce Gaps by Region (Australia, 2023)

An analysis of how optometrists and ophthalmologists are distributed across
Australia's 31 Primary Health Networks (PHNs), built in SQL Server using a
bronze / silver / gold layered approach, with a Power BI dashboard.

**Status:** 🚧 In progress — bronze layer complete; silver, gold and dashboard underway.

## Why this project

I'm an optometrist moving into data. In practice, referring a patient to an
ophthalmologist can mean very different waits depending on where they live.
This project asks:

1. **Referral pressure:** Where is the ratio of optometrists to ophthalmologists highest?
2. **Access:** Where is ophthalmologist access lowest — per total population and per person aged 65+?
3. **Age adjustment:** Which regions look worse once you account for an older population?

Eye disease such as glaucoma, cataract and macular degeneration is concentrated
in older people, so access per person aged 65+ may reflect need better than
access per total population.

## Data sources

| Dataset | Source | Detail |
|---|---|---|
| Optometrists by PHN, 2023 | [AIHW – Eye health measures 2025, Workforce data tables](https://www.aihw.gov.au/reports/indigenous-australians/eye-health-measures-data-2025/data) (IHW-304), Table 4.1d | Headcount and FTE per 100,000 |
| Ophthalmologists by PHN, 2023 | Same file, Table 4.2d | Headcount and FTE per 100,000 |
| Population by age, by PHN, 2023 ERP | [PHIDU Social Health Atlas of Australia](https://phidu.torrens.edu.au/social-health-atlases/data-archive/data-archive-social-health-atlases-of-australia) (Dec 2024 release) | Total persons and persons aged 65+ |

Note: the workforce tables come from AIHW's Aboriginal and Torres Strait
Islander eye health report, but the workforce measures cover **all**
practitioners and the **total** Australian population.

## Architecture

| Layer | Purpose |
|---|---|
| **Bronze** | Raw CSVs loaded as-is (all text) |
| **Silver** | Cleaned and standardised: PHN rows only, deduplicated, 'n.p.' → NULL with suppression flag, numeric types, clear names |
| **Gold** | One row per PHN with rates, ratios, rankings and flags, ready for analysis and Power BI |

## Repository structure

```
bronze/ ddl_bronze.sql, quality_checks_bronze.sql
```

Silver, gold, analysis and dashboard folders will be added as the project progresses.

## Data quality (bronze)

- All three tables contain 31 PHNs, and PHN codes match across all tables
  (full anti-join returned 0 rows; validated with a deliberate mismatch test).
- Workforce totals reconcile to AIHW national figures: **6,267 optometrists**
  and **1,004 ophthalmologists** (2023).
- **Suppressed values:** AIHW does not publish FTE rates for small numbers
  ('n.p.'). 1 optometrist rate and 7 ophthalmologist rates are suppressed,
  all regional. These become NULL with a flag — never 0.
- **Duplicates in source:** the PHIDU file lists every PHN twice (in the
  detailed listing and in a 'PHN totals' section). Copies were verified
  identical and deduplicated.
- Deduplicated total population is **26,643,901**, matching the ABS estimated
  resident population for June 2023 (~26.6 million).

Full details: `bronze/quality_checks_bronze.sql`

## Key findings

_To be completed once the gold layer and analysis are finished._

- Referral pressure (optometrists per ophthalmologist) by region: TBC
- Lowest ophthalmologist access per 100,000 aged 65+: TBC
- Regions that rank worse after age adjustment: TBC

## Limitations

- **Snapshot:** data is for 2023 only.
- **Where practitioners work, not where patients are seen:** people travel
  for care, and visiting and outreach services are not captured.
- **Headcount vs FTE:** rates for suppressed regions are calculated from
  headcount, which does not reflect hours worked.
- **Small numbers:** rates for regions with few practitioners are unstable.
- **Age is only one driver of need:** diabetes, socioeconomic factors and
  other conditions also affect demand.
- Population (PHIDU) and workforce (AIHW) data come from different
  publishers; PHN codes were checked to match exactly.

## Tools

SQL Server (SSMS) · Power BI · GitHub

## Author

Shirwa Abdi-hashi — optometrist moving into data engineering.
