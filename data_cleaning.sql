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
FROM layoffs_staging2;

-- 2. Standardize column values

-- industry
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

select * 
from layoffs_staging2 
where industry like 'Crypto%'; 

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- location
select distinct country
from layoffs_staging2
order by 1
;

select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%'
;

-- date
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

alter table layoffs_staging2
modify column `date` date;

-- 3. Fix null or blank values
select * 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

update layoffs_staging2
set industry = null
where industry = '';

select * 
from layoffs_staging2
where industry is null 
or industry = '';

select * 
from layoffs_staging2
where company = 'Airbnb';

select t1.industry, t2.industry
from layoffs_staging2 t1 
join layoffs_staging2 t2
	on t1.company = t2.company
where (t1.industry is null)
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null)
and t2.industry is not null;

select * 
from layoffs_staging2;
    
-- 4. Remove extra columns

select * 
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null;

delete 
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null;

select * 
from layoffs_staging2;

alter table layoffs_staging2
drop column row_num;

select * 
from layoffs_staging2;