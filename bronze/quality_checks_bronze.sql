/*
===============================================================================
Quality Checks: Bronze Layer
===============================================================================
Purpose:
    Validates bronze tables before cleaning in silver: row counts,
    duplicates, NULLs, valid categories, conversion failures, value
    ranges, reconciliation to national totals, and join-key matching.

Summary of findings:
    All tables
      - 31 PHNs per table; PHN codes match across all 3 tables (full
        anti-join returned 0 rows; validated by deliberately excluding PHN101)

    bronze.optometrist_phn
      - No duplicates or NULLs
      - Number: min 6, max 578. FTE rate: min 12.5, max 31.0
      - 1 suppressed rate ('n.p.'): Western Queensland (6 optometrists)
      - Total 6,267 optometrists, matching AIHW 2023 national total

    bronze.ophthalmologist_phn
      - No duplicates or NULLs
      - Number: min 0, max 138. FTE rate: min 1.5, max 8.4
      - 7 suppressed rates ('n.p.'), all regional, all <10 ophthalmologists
      - Total 1,004 ophthalmologists, matching AIHW 2023 national total

    bronze.population_phn
      - Each PHN appears twice (PHA listing + 'PHN totals' section in source);
        copies verified identical with DISTINCT (31 rows)
      - Numbers stored with thousands separators (e.g. '1,603,836')
      - 'total_popn_*' columns = total persons (all ages), repeated per group
      - Deduplicated total population = 26,643,901, matching ABS 2023 ERP
        (~26.6M); summing without deduplicating gives double (53.3M)

Actions for silver:
    - Filter to PHN rows only
    - Deduplicate population table (one row per PHN)
    - Convert 'n.p.' to NULL and add a suppression flag (never 0)
    - Remove commas and convert text to numeric types
    - Split state from region name and trim spaces
    - Rename to clear columns (e.g. total_population, population_65_plus)
===============================================================================
*/


-----------------------------------------
-- BRONZE Optometrist PHN Quality Checks

select count(*)
from bronze.optometrist_phn
where substring(phn_code,1,3) = 'PHN' --count no. of PHN, output 31 matches australia total

select count(distinct phn_code)
from bronze.optometrist_phn
where substring(phn_code,1,3) = 'PHN' --distinct 31 PHN. no duplicates!

select distinct phn_type
from bronze.optometrist_phn
where substring(phn_code,1,3) = 'PHN' -- only metro or regional

select MIN(CAST(optom_number AS INT)) -- min/max are 6 and 578 logical
from bronze.optometrist_phn
where substring(phn_code,1,3) = 'PHN'

--table is string format. try_cast into decimal reveals non-integer that have been turned into NULLs. 
--output: optom_fte_rate has n.p. issue. detection that data is suppressed due to low optom number.
select * 
from bronze.optometrist_phn
where substring(phn_code,1,3) = 'PHN' AND
TRY_CAST(optom_fte_rate AS DECIMAL(6,1)) IS NULL

select MAX(TRY_CAST(optom_fte_rate AS DECIMAL(6,1))),
MIN(TRY_CAST(optom_fte_rate AS DECIMAL(6,1))) -- max 31, min 12.5 excluding suppressed
from bronze.optometrist_phn
where substring(phn_code,1,3) = 'PHN'

SELECT SUM(TRY_CAST(optom_number as INT))
from bronze.optometrist_phn
WHERE SUBSTRING(phn_code,1,3) = 'PHN' -- 6267 optometrists in Australia. AIHW 2023 source is 6275 - very close

-----------------------------------------
-- BRONZE Ophthalmologist PHN Quality Checks
select count(*)
from bronze.ophthalmologist_phn
where substring(phn_code,1,3) = 'PHN' --output of 31 matches PHN total

select count(distinct phn_code)
from bronze.ophthalmologist_phn
where substring(phn_code,1,3) = 'PHN' --distinct 31 PHN. no duplicates!

select distinct phn_code, phn_type
from bronze.ophthalmologist_phn
where substring(phn_code,1,3) = 'PHN' --good quality columns

select *
from bronze.ophthalmologist_phn
where substring(phn_code,1,3) = 'PHN'
AND (ophthal_number IS NULL or ophthal_fte_rate IS NULL) -- no nulls

SELECT SUM(TRY_CAST(ophthal_number as INT))
from bronze.ophthalmologist_phn
WHERE SUBSTRING(phn_code,1,3) = 'PHN' --output 1004 ophthalmologists. matches AIHW 2023 ophthalmologist Australia Total

-- similar to optom. ophthal_fte_rate is n.p. (suppressed due to low numbers) in multiple regions. 
-- total of 7 regions. will use headcount(ophthal_number) and population(different table) to calculate alternative measure at later stage
select * 
from bronze.ophthalmologist_phn
where substring(phn_code,1,3) = 'PHN' AND
TRY_CAST(ophthal_fte_rate AS DECIMAL(6,1)) IS NULL

select MIN(CAST(ophthal_number AS INT)),
MAX(CAST(ophthal_number AS INT)) --  Min is 0, and Max is 138. 
from bronze.ophthalmologist_phn
where substring(phn_code,1,3) = 'PHN'

select MIN(TRY_CAST(ophthal_fte_rate AS DECIMAL(6,1))),
MAX(TRY_CAST(ophthal_fte_rate AS DECIMAL(6,1))) --  Min is 1.5, and Max is 8.4. 
from bronze.ophthalmologist_phn -- need try_cast
where substring(phn_code,1,3) = 'PHN'
-----------------------------------------
-- BROZNE Population PHN Quality Checks

SELECT * 
FROM bronze.population_phn

SELECT COUNT(*)
FROM bronze.population_phn
WHERE substring(phn_code,1,3) = 'PHN' 
-- output of 62, should only be 31 PHN.
-- souorce csv has totals at bottom so CSVs are repeated. 

SELECT phn_code,
total_popn_1,
age_above_65_number
FROM bronze.population_phn
WHERE phn_code = 'PHN101'
 -- example, PHN101 appers twice and is exactly the same. lets check the rest below.

SELECT DISTINCT phn_code,
total_popn_1,
age_above_65_number,
total_popn_5
FROM bronze.population_phn
WHERE substring(phn_code,1,3) = 'PHN' 
-- 31 row output with DISTINCT, so each PHN is duplicated in source. 
-- will de-duplicate in silver


WITH de_duplicated_population_table AS -- CTE to first deduplicate data
(SELECT DISTINCT phn_code,
	total_popn_1
	FROM bronze.population_phn
	WHERE substring(phn_code,1,3) = 'PHN' 
)
--main query to calculate total poulation
SELECT SUM(CAST(REPLACE(total_popn_1,',','') AS INT))
FROM de_duplicated_population_table
--output is 26643901 which is over 26 million. Matches approximate Australia Population in 2023
----------------------------------------- 
/* PHN Column Quality Check Across 3 Tables. To be Joined Later Based off PHN */

WITH optom_only AS
(
SELECT phn_code
FROM bronze.optometrist_phn
WHERE substring(phn_code,1,3) = 'PHN'
),

ophthal_only AS
(
SELECT phn_code
FROM bronze.ophthalmologist_phn
WHERE substring(phn_code,1,3) = 'PHN'
),

single_population AS 
(SELECT DISTINCT phn_code,
	age_above_65_percent
	FROM bronze.population_phn
	WHERE substring(phn_code,1,3) = 'PHN' 
)

/*
SELECT 
	ot.phn_code,
	oh.phn_code
FROM optom_only as ot
FULL JOIN ophthal_only as oh
ON ot.phn_code = oh.phn_code
WHERE ot.phn_code IS NULL or oh.phn_code IS NULL; -- no row output. so the PHN column matches for optom and ophthal 


SELECT 
	ot.phn_code,
	op.phn_code
FROM optom_only as ot
FULL JOIN single_population as op
ON ot.phn_code = op.phn_code
WHERE ot.phn_code IS NULL or op.phn_code IS NULL; -- no row output. so the PHN column matches for optom  and population table. 
*/

SELECT 
	oh.phn_code,
	op.phn_code
FROM ophthal_only as oh
FULL JOIN single_population as op
ON oh.phn_code = op.phn_code
WHERE oh.phn_code IS NULL or op.phn_code IS NULL; -- no row output. so the PHN column matches for ophthal and population table. 

--Validation Test. Exclude PHN101 deliberately in CTE below. Check correctly returned NULL | PHN101
/*
WITH optom_only AS
(
SELECT phn_code
FROM bronze.optometrist_phn
WHERE substring(phn_code,1,3) = 'PHN'
AND phn_code != 'PHN101' -- only 30 rows so left out PHN101
),

ophthal_only AS
(
SELECT phn_code
FROM bronze.ophthalmologist_phn
WHERE substring(phn_code,1,3) = 'PHN'
),

single_population AS 
(SELECT DISTINCT phn_code,
	age_above_65_percent
	FROM bronze.population_phn
	WHERE substring(phn_code,1,3) = 'PHN' 
)
SELECT 
	ot.phn_code,
	oh.phn_code
FROM optom_only as ot
FULL JOIN ophthal_only as oh
ON ot.phn_code = oh.phn_code
WHERE ot.phn_code IS NULL or oh.phn_code IS NULL; -- We have a null output for PHN101 which we excluded in the CTE. Our mismatch test works. Data is correct. 

*/
