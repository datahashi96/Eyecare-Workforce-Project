/*
===============================================================================
Quality Checks: Silver Layer
===============================================================================
Purpose:
    Confirms the silver tables are complete, consistent and ready for gold.

Summary of findings:
    - Each table has 31 rows, one per PHN
    - Totals reconcile to source:
        optometrists 6,267 (AIHW 2023)
        ophthalmologists 1,004 (AIHW 2023)
        population 26,643,901 (ABS 2023 estimated resident population)
    - All 8 states/territories extracted correctly
    - Suppressed rates: 1 optometrist PHN, 7 ophthalmologist PHNs
      (all regional); each is NULL with flag = 1
    - No unexpected NULLs in population figures
    - PHN codes match across all three tables (anti-join returns 0 rows)

Notable finding:
    Western Queensland (PHN305) has 0 ophthalmologists. This is a true zero
    (headcount = 0), not a suppressed value.

Ready for gold:
    Join on phn_code. Use NULLIF on ophthalmologist counts to avoid
    divide-by-zero for PHN305.
===============================================================================
*/


--scratchboard at top. optometrist, then ophthalmologist then population table quality checks after with line break
---------------------------------------------------------------------------

SELECT 
	phn_name,
	UPPER(TRIM(SUBSTRING(phn_name,CHARINDEX('(',phn_name) + 1, (CHARINDEX(')',phn_name) - 1) - (CHARINDEX('(',phn_name) + 1))))
FROM bronze.optometrist_phn
WHERE substring(phn_code,1,3) = 'PHN'

SELECT DISTINCT UPPER(TRIM(SUBSTRING(phn_name,CHARINDEX('(',phn_name) + 1, (CHARINDEX(')',phn_name) - 1) - (CHARINDEX('(',phn_name) + 1))))
FROM bronze.optometrist_phn
WHERE substring(phn_code,1,3) = 'PHN' -- correct state data

-- Silver Optometrist Table checks

SELECT COUNT(*)
FROM silver.optometrist_phn -- matches PHN COUNT

SELECT SUM(optom_number)
FROM silver.optometrist_phn -- 6267, matches AIHW 2023 total

SELECT *
FROM silver.optometrist_phn
WHERE optom_fte_rate IS NULL -- null check and flagged. 

SELECT *
FROM silver.optometrist_phn
WHERE optom_rate_suppressed = 1 -- null check and flagged. 

SELECT DISTINCT aus_state
FROM silver.optometrist_phn -- all 8 aus states all formatted and listed

-- Silver Ophthalmologist Table checks

SELECT COUNT(*)
FROM silver.ophthalmologist_phn -- matches PHN COUNT

SELECT SUM(ophthal_number)
FROM silver.ophthalmologist_phn -- 1004, matches AIHW 2023 total

SELECT *
FROM silver.ophthalmologist_phn
WHERE ophthal_fte_rate IS NULL -- null check and flagged. 

SELECT *
FROM silver.ophthalmologist_phn
WHERE ophthal_rate_suppressed = 1 -- null check and flagged. 

SELECT DISTINCT aus_state
FROM silver.ophthalmologist_phn -- all 8 aus states all formatted and listed

SELECT *
FROM silver.ophthalmologist_phn
WHERE ophthal_number = 0 -- Western Queensland, PHN305 has 0 ophthalmologists!

-- Silver Population Table Checks

SELECT COUNT(*)
FROM silver.population_phn -- 31 PHN, correct

SELECT SUM(total_popn)
FROM silver.population_phn --26643901. Matches 2023 ABS estimated resident population

SELECT *
from silver.population_phn
WHERE age_above_65_number IS NULL OR total_popn IS NULL or age_above_65_percent IS NULL -- no NULLs in data

-- Final PHN check (AntiJoin) before Gold
SELECT 
	ot.phn_code,
	oh.phn_code
FROM silver.optometrist_phn as ot
FULL JOIN silver.ophthalmologist_phn as oh
ON ot.phn_code = oh.phn_code
WHERE ot.phn_code IS NULL or oh.phn_code is NULL -- 0 rows, all 31 PHN codes match
SELECT 
	ot.phn_code,
	op.phn_code
FROM silver.optometrist_phn as ot
FULL JOIN silver.population_phn as op
ON ot.phn_code = op.phn_code
WHERE ot.phn_code IS NULL or op.phn_code is NULL -- 0 rows, all 31 PHN codes match
SELECT 
	oh.phn_code,
	op.phn_code
FROM silver.ophthalmologist_phn as oh
FULL JOIN silver.population_phn as op
ON oh.phn_code = op.phn_code
WHERE oh.phn_code IS NULL or op.phn_code is NULL -- 0 rows, all 31 PHN codes match
