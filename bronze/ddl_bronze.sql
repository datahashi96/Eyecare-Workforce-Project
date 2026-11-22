/*
===============================================================================
DDL Script: Create and Load Bronze Tables
===============================================================================
Project: Eye Care Workforce Gaps by Region (Australia, 2023)
Layer: Bronze (raw data, loaded as-is from source files)

Purpose:
    Creates the bronze tables and loads raw CSV data with BULK INSERT.
    All columns are stored as NVARCHAR so values like 'n.p.' and
    comma-formatted numbers load without errors. Cleaning happens in silver.

Tables:
    bronze.optometrist_phn - AIHW IHW-304 (2025 edition), Table 4.1d
                                   Optometrists by PHN, 2023
    bronze.ophthalmologist_phn - AIHW IHW-304 (2025 edition), Table 4.2d
                                   Ophthalmologists by PHN, 2023
    bronze.population_phn - PHIDU Social Health Atlas (Dec 2024 release)
                                   Population by broad age group, 2023 ERP

Load notes:
    - AIHW files: header cell contains a line break; FIRSTROW adjusted so the
      first data row (PHN101) is loaded. Verified by checking the first row.
    - PHIDU file: 33 columns, including 7 blank spacer columns between
      age groups. Quoted numbers with commas loaded using FORMAT = 'CSV'.
    - ROWTERMINATOR = '0x0a' (line feed) used for all files.
    - Footer notes and non-PHN rows are loaded as-is and filtered in silver.

Execution notes:
    Statements were run individually in order: CREATE TABLE, then
    BULK INSERT, for each table. Tables were truncated or dropped manually
    when a reload was needed.
===============================================================================
*/


CREATE DATABASE eyecare_workforce;
GO

USE eyecare_workforce;
GO

CREATE SCHEMA bronze;
GO


CREATE TABLE bronze.optometrist_phn (
	phn_name NVARCHAR(1000),
	phn_code NVARCHAR(50),
	phn_type NVARCHAR(50),
	optom_number NVARCHAR(50),
	optom_fte_rate NVARCHAR(50)
	);


BULK INSERT bronze.optometrist_phn
	FROM 'C:\sql\Eyecare_Workforce_Project\datasets\AIHW\aihw_tables_csv\Table 4.1d.csv'
	WITH (
		FORMAT = 'CSV',
		FIRSTROW = 3,
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '0x0a'
		);

CREATE TABLE bronze.ophthalmologist_phn (
	phn_name NVARCHAR(1000),
	phn_code NVARCHAR(50),
	phn_type NVARCHAR(50),
	ophthal_number NVARCHAR(50),
	ophthal_fte_rate NVARCHAR(50)
	);

BULK INSERT bronze.ophthalmologist_phn 
	FROM 'C:\sql\Eyecare_Workforce_Project\datasets\AIHW\aihw_tables_csv\Table 4.2d.csv'
	WITH (
		FORMAT = 'CSV',
		FIRSTROW = 3,
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '0x0a'
		);


BULK INSERT bronze.population_phn
	FROM 'C:\sql\Eyecare_Workforce_Project\datasets\PHIDU\Age_distribution_Persons_broad.csv'
	WITH (
		FORMAT = 'CSV',
		FIRSTROW = 6,
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '0x0a'
		);


CREATE TABLE bronze.population_phn (
	phn_code NVARCHAR(50),
	phn_name NVARCHAR(1000),
	age_0_14_number NVARCHAR(50),
	total_popn_1 NVARCHAR(50),
	age_0_14_percent NVARCHAR(50),
	blank_1 NVARCHAR(50),
	age_15_24_number NVARCHAR(50),
	total_popn_2 NVARCHAR(50),
	age_15_24_percent NVARCHAR(50),
	blank_2 NVARCHAR(50),
	age_25_44_number NVARCHAR(50),
	total_popn_3 NVARCHAR(50),
	age_25_44_percent NVARCHAR(50),
	blank_3 NVARCHAR(50),
	age_45_64_number NVARCHAR(50),
	total_popn_4 NVARCHAR(50),
	age_45_64_percent NVARCHAR(50),
	blank_4 NVARCHAR(50),
	age_above_65_number NVARCHAR(50),
	total_popn_5 NVARCHAR(50),
	age_above_65_percent NVARCHAR(50),
	blank_5 NVARCHAR(50),
	age_above_70_number NVARCHAR(50),
	total_popn_6 NVARCHAR(50),
	age_above_70_percent NVARCHAR(50),
	blank_6 NVARCHAR(50),
	age_above_75_number NVARCHAR(50),
	total_popn_7 NVARCHAR(50),
	age_above_75_percent NVARCHAR(50),
	blank_7 NVARCHAR(50),
	age_above_85_number NVARCHAR(50),
	total_popn_8 NVARCHAR(50),
	age_above_85_percent NVARCHAR(50)
	);

select *
from bronze.optometrist_phn
