/*
===============================================================================
DDL Script: Create and Load Silver Tables
===============================================================================
Purpose:
    Creates the silver tables and loads cleaned data from bronze.
    Each table keeps only the 31 PHN rows and converts text to proper types.

Tables:
    silver.optometrist_phn - optometrist headcount and FTE rate per PHN
    silver.ophthalmologist_phn - ophthalmologist headcount and FTE rate per PHN
    silver.population_phn - total and 65+ population per PHN

Transformations:
    - Filtered to PHN rows only (excluded state and national totals)
    - Split "PHN name (STATE)" into phn_name and aus_state
    - Converted numbers from text to INT and DECIMAL(6,1)
    - Suppressed rates ('n.p.') set to NULL and flagged (rate_suppressed = 1),
      never set to 0
    - Removed thousands separators from population figures before casting
    - Deduplicated population rows with SELECT DISTINCT

Execution notes:
    Statements were run individually in order. Tables were truncated
    manually before a reload to avoid duplicate rows.
===============================================================================
*/



CREATE SCHEMA silver;
GO

---------------------------------------------------
--Optometrist Silver Table

CREATE TABLE silver.optometrist_phn (
	phn_name NVARCHAR(100),
	aus_state NVARCHAR(50),
	phn_code NVARCHAR(50),
	phn_type NVARCHAR(50),
	optom_number INT,
	optom_fte_rate DECIMAL(6,1),
	optom_rate_suppressed BIT
	);

INSERT INTO silver.optometrist_phn (
	phn_name,
	aus_state,
	phn_code,
	phn_type,
	optom_number,
	optom_fte_rate,
	optom_rate_suppressed
	)
SELECT 
	TRIM(LEFT(phn_name,CHARINDEX('(',phn_name) -1)) as phn_name,
	UPPER(TRIM(SUBSTRING(phn_name,CHARINDEX('(',phn_name) + 1, (CHARINDEX(')',phn_name) - 1) - (CHARINDEX('(',phn_name) + 1)))) as aus_state,
	phn_code,
	phn_type,
	TRY_CAST(optom_number as INT),
	TRY_CAST(optom_fte_rate as DECIMAL(6,1)), -- try_cast to turn n.p. we discovered in bronze to null. 
	CASE WHEN optom_fte_rate = 'n.p.' THEN 1 -- highlight null with flag
	ELSE 0
	END
FROM bronze.optometrist_phn
WHERE substring(phn_code,1,3) = 'PHN'

---------------------------------------------------
--Ophthalmologist Silver Table

CREATE TABLE silver.ophthalmologist_phn (
	phn_name NVARCHAR(100),
	aus_state NVARCHAR(50),
	phn_code NVARCHAR(50),
	phn_type NVARCHAR(50),
	ophthal_number INT,
	ophthal_fte_rate DECIMAL(6,1),
	ophthal_rate_suppressed BIT
	);


INSERT INTO silver.ophthalmologist_phn (
	phn_name,
	aus_state,
	phn_code,
	phn_type,
	ophthal_number,
	ophthal_fte_rate,
	ophthal_rate_suppressed
	)
SELECT 
	TRIM(LEFT(phn_name,CHARINDEX('(',phn_name) -1)) as phn_name,
	UPPER(TRIM(SUBSTRING(phn_name,CHARINDEX('(',phn_name) + 1, (CHARINDEX(')',phn_name) - 1) - (CHARINDEX('(',phn_name) + 1)))) as aus_state,
	phn_code,
	phn_type,
	TRY_CAST(ophthal_number as INT),
	TRY_CAST(ophthal_fte_rate as DECIMAL(6,1)),
	CASE WHEN ophthal_fte_rate = 'n.p.' THEN 1
	ELSE 0
	END
FROM bronze.ophthalmologist_phn
WHERE substring(phn_code,1,3) = 'PHN'

CREATE TABLE silver.population_phn(
	phn_name NVARCHAR(100),
	phn_code  NVARCHAR(50),
	age_above_65_number INT,
	total_popn INT,
	age_above_65_percent DECIMAL(4,1)
	);

INSERT INTO silver.population_phn (
	phn_name,
	phn_code,
	age_above_65_number,
	total_popn,
	age_above_65_percent
	)

SELECT DISTINCT --deduplicate data
	TRIM(phn_name),
	phn_code,
	CAST(REPLACE(age_above_65_number,',','') as INT),
	CAST(REPLACE(total_popn_5,',','') as INT),
	CAST(age_above_65_percent as DECIMAL(4,1))
from bronze.population_phn
WHERE substring(phn_code,1,3) = 'PHN' 



