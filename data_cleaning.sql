-- Layoffs Data - Data Cleaning
SELECT *
FROM layoffs;

-- 0. Copy table to save Raw
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

-- 1. Remove Duplicates

SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY company, industry, total_laid_off, percentage_laid_off,`date`) AS row_num
		FROM 
        layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY company, industry, total_laid_off,percentage_laid_off,`date`,stage
    , country, funds_raised_millions) AS row_num
	FROM 
        layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Check one company to confirm
SELECT * 
from layoffs_staging
WHERE company = 'Oda';

-- these are our real duplicates 
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

-- these are the ones we want to delete where the row number is > 1 
-- create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column

ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;

SELECT *
FROM world_layoffs.layoffs_staging
;

CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- now that we have this we can delete rows were row_num is greater than 2

DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;

SELECT * 
FROM layoffs_staging2

-- 2. Standardize column values

SELECT company, TRIM(company)
FROM layoffs_staging2
;
-- 3. Fix null or blank values

-- 4. Remove extra columns