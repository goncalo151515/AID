USE aid_staging;

-- >>> Section 1 - Row counts and countries per source <<<

-- 1.1 Row count per staging table
SELECT 'stg_maddison' AS source_table, COUNT(*) AS n_rows FROM stg_maddison
UNION ALL
SELECT 'stg_wdi', COUNT(*) FROM stg_wdi
UNION ALL
SELECT 'stg_events', COUNT(*) FROM stg_events;

-- 1.2 Distinct countries in Maddison
SELECT country_iso3, country_name, COUNT(*) AS n_rows
FROM stg_maddison
GROUP BY country_iso3, country_name
ORDER BY country_iso3;

-- 1.3 Distinct countries in WDI
SELECT country_iso3, country_name, COUNT(*) AS n_rows
FROM stg_wdi
GROUP BY country_iso3, country_name
ORDER BY country_iso3;

-- 1.4 Distinct countries in events
SELECT country_iso3, country_name, COUNT(*) AS n_events
FROM stg_events
GROUP BY country_iso3, country_name
ORDER BY country_iso3;

-- 1.5 Country presence across the three sources
SELECT iso3,
  MAX(src = 'maddison') AS in_maddison,
  MAX(src = 'wdi') AS in_wdi,
  MAX(src = 'events') AS in_events
FROM (
  SELECT DISTINCT country_iso3 AS iso3, 'maddison' AS src FROM stg_maddison
  UNION ALL
  SELECT DISTINCT country_iso3, 'wdi' FROM stg_wdi
  UNION ALL
  SELECT DISTINCT country_iso3, 'events' FROM stg_events
) AS t
GROUP BY iso3
ORDER BY iso3;

-- >>> Section 2 - Year ranges and temporal coverage <<<

-- 2.1 Overall year range per source
SELECT 'stg_maddison' AS source_table, MIN(year) AS first_year, MAX(year) AS last_year,
  COUNT(DISTINCT year) AS n_distinct_years
FROM stg_maddison
UNION ALL
SELECT 'stg_wdi', MIN(year), MAX(year), COUNT(DISTINCT year) FROM stg_wdi
UNION ALL
SELECT 'stg_events', MIN(year), MAX(year), COUNT(DISTINCT year) FROM stg_events;

-- 2.2 Year range per country and indicator in Maddison
SELECT country_iso3, indicator_code,
  MIN(year) AS first_year, MAX(year) AS last_year,
  COUNT(*) AS n_years,
  (MAX(year) - MIN(year) + 1) - COUNT(*) AS missing_inside
FROM stg_maddison
GROUP BY country_iso3, indicator_code
ORDER BY country_iso3, indicator_code;

-- 2.3 Exact missing-year intervals inside each series in Maddison
WITH RECURSIVE years AS (
  SELECT 1900 AS year
  UNION ALL
  SELECT year + 1 FROM years WHERE year < 2022
),
spans AS (
  SELECT country_iso3, indicator_code, MIN(year) AS first_year, MAX(year) AS last_year
  FROM stg_maddison
  GROUP BY country_iso3, indicator_code
),
missing AS (
  SELECT s.country_iso3, s.indicator_code, y.year
  FROM spans s
  JOIN years y ON y.year BETWEEN s.first_year AND s.last_year
  LEFT JOIN stg_maddison m
    ON m.country_iso3 = s.country_iso3
    AND m.indicator_code = s.indicator_code
    AND m.year = y.year
  WHERE m.year IS NULL
),
grouped AS (
  SELECT country_iso3, indicator_code, year,
    year - ROW_NUMBER() OVER (PARTITION BY country_iso3, indicator_code ORDER BY year) AS grp
  FROM missing
)
SELECT country_iso3, indicator_code,
  MIN(year) AS gap_start, MAX(year) AS gap_end, COUNT(*) AS n_missing
FROM grouped
GROUP BY country_iso3, indicator_code, grp
ORDER BY country_iso3, indicator_code, gap_start;

-- 2.4 Year range per country in WDI
SELECT country_iso3, MIN(year) AS first_year, MAX(year) AS last_year,
  COUNT(DISTINCT indicator_code) AS n_indicators
FROM stg_wdi
GROUP BY country_iso3
ORDER BY country_iso3;

-- 2.5 Year range per country in events
SELECT country_iso3, MIN(year) AS first_year, MAX(year) AS last_year,
  COUNT(*) AS n_events
FROM stg_events
GROUP BY country_iso3
ORDER BY country_iso3;

-- >>> Section 3 - WDI indicators and temporal coverage per indicator <<<

-- 3.1 List of WDI indicators
SELECT indicator_code, indicator_name,
  COUNT(DISTINCT country_iso3) AS n_countries,
  MIN(year) AS first_year, MAX(year) AS last_year,
  COUNT(*) AS n_rows
FROM stg_wdi
WHERE value IS NOT NULL
GROUP BY indicator_code, indicator_name
ORDER BY indicator_code;

-- 3.2 First year with data
SELECT indicator_code,
  MIN(CASE WHEN country_iso3 = 'PRT' THEN year END) AS PRT,
  MIN(CASE WHEN country_iso3 = 'ESP' THEN year END) AS ESP,
  MIN(CASE WHEN country_iso3 = 'FRA' THEN year END) AS FRA,
  MIN(CASE WHEN country_iso3 = 'DEU' THEN year END) AS DEU,
  MIN(CASE WHEN country_iso3 = 'BEL' THEN year END) AS BEL,
  MIN(CASE WHEN country_iso3 = 'ITA' THEN year END) AS ITA,
  MIN(CASE WHEN country_iso3 = 'IRL' THEN year END) AS IRL,
  MIN(CASE WHEN country_iso3 = 'GRC' THEN year END) AS GRC,
  MIN(CASE WHEN country_iso3 = 'POL' THEN year END) AS POL,
  MIN(CASE WHEN country_iso3 = 'CZE' THEN year END) AS CZE,
  MIN(CASE WHEN country_iso3 = 'HUN' THEN year END) AS HUN,
  MIN(CASE WHEN country_iso3 = 'ROU' THEN year END) AS ROU,
  MIN(CASE WHEN country_iso3 = 'EST' THEN year END) AS EST,
  MIN(CASE WHEN country_iso3 = 'LVA' THEN year END) AS LVA,
  MIN(CASE WHEN country_iso3 = 'LTU' THEN year END) AS LTU,
  MIN(CASE WHEN country_iso3 = 'EUU' THEN year END) AS EUU
FROM stg_wdi
WHERE value IS NOT NULL
GROUP BY indicator_code
ORDER BY indicator_code;

-- 3.3 Number of years with data
SELECT indicator_code,
  SUM(country_iso3 = 'PRT') AS PRT,
  SUM(country_iso3 = 'ESP') AS ESP,
  SUM(country_iso3 = 'FRA') AS FRA,
  SUM(country_iso3 = 'DEU') AS DEU,
  SUM(country_iso3 = 'BEL') AS BEL,
  SUM(country_iso3 = 'ITA') AS ITA,
  SUM(country_iso3 = 'IRL') AS IRL,
  SUM(country_iso3 = 'GRC') AS GRC,
  SUM(country_iso3 = 'POL') AS POL,
  SUM(country_iso3 = 'CZE') AS CZE,
  SUM(country_iso3 = 'HUN') AS HUN,
  SUM(country_iso3 = 'ROU') AS ROU,
  SUM(country_iso3 = 'EST') AS EST,
  SUM(country_iso3 = 'LVA') AS LVA,
  SUM(country_iso3 = 'LTU') AS LTU,
  SUM(country_iso3 = 'EUU') AS EUU
FROM stg_wdi
WHERE value IS NOT NULL
GROUP BY indicator_code
ORDER BY indicator_code;

-- >>> Section 4 - Missing values <<<

-- 4.1 Explicit NULL values
SELECT 'stg_maddison' AS source_table, COUNT(*) AS n_rows,
  SUM(value IS NULL) AS n_null_values
FROM stg_maddison
UNION ALL
SELECT 'stg_wdi', COUNT(*), SUM(value IS NULL) FROM stg_wdi;

-- 4.2 Missing or empty text fields in events
SELECT
  SUM(category IS NULL OR category = '') AS n_missing_category,
  SUM(economic_impact IS NULL OR economic_impact = '') AS n_missing_impact,
  SUM(event IS NULL OR event = '') AS n_missing_event
FROM stg_events;

-- 4.3 Maddison country-years with only some of the 3 indicators
WITH m AS (
  SELECT country_iso3, year,
    MAX(CASE WHEN indicator_code = 'gdp' THEN value END) AS gdp,
    MAX(CASE WHEN indicator_code = 'gdppc' THEN value END) AS gdppc,
    MAX(CASE WHEN indicator_code = 'pop' THEN value END) AS pop
  FROM stg_maddison
  GROUP BY country_iso3, year
)
SELECT country_iso3, COUNT(*) AS n_partial_years,
  MIN(year) AS first_partial_year, MAX(year) AS last_partial_year
FROM m
WHERE gdp IS NULL OR gdppc IS NULL OR pop IS NULL
GROUP BY country_iso3
ORDER BY country_iso3;

-- >>> Section 5 - Data integrity checks <<<

-- 5.1 Checks event uniqueness
SELECT 'stg_maddison' AS source_table, COUNT(*) AS n_duplicate_keys
FROM (
  SELECT 1 FROM stg_maddison
  GROUP BY country_iso3, indicator_code, year
  HAVING COUNT(*) > 1
) AS d
UNION ALL
SELECT 'stg_wdi', COUNT(*)
FROM (
  SELECT 1 FROM stg_wdi
  GROUP BY country_iso3, indicator_code, year
  HAVING COUNT(*) > 1
) AS d
UNION ALL
SELECT 'stg_events', COUNT(*)
FROM (
  SELECT 1 FROM stg_events
  GROUP BY year, country_iso3, event
  HAVING COUNT(*) > 1
) AS d;

-- 5.2 Same ISO3 code always with the same country name across sources
SELECT country_iso3, COUNT(DISTINCT country_name) AS n_names,
  GROUP_CONCAT(DISTINCT country_name) AS names
FROM (
  SELECT country_iso3, country_name FROM stg_maddison
  UNION
  SELECT country_iso3, country_name FROM stg_wdi
  UNION
  SELECT country_iso3, country_name FROM stg_events
) AS t
GROUP BY country_iso3
HAVING COUNT(DISTINCT country_name) > 1;

-- 5.3 Gdp should equal gdppc x pop x 1000
WITH m AS (
  SELECT country_iso3, year,
    MAX(CASE WHEN indicator_code = 'gdp' THEN value END) AS gdp,
    MAX(CASE WHEN indicator_code = 'gdppc' THEN value END) AS gdppc,
    MAX(CASE WHEN indicator_code = 'pop' THEN value END) AS pop
  FROM stg_maddison
  GROUP BY country_iso3, year
)
SELECT COUNT(*) AS n_complete_country_years,
  SUM(ABS(gdp - gdppc * pop * 1000) / gdp > 0.01) AS n_diff_above_1pct,
  MAX(ABS(gdp - gdppc * pop * 1000) / gdp) AS max_relative_diff
FROM m
WHERE gdp IS NOT NULL AND gdppc IS NOT NULL AND pop IS NOT NULL;

-- 5.4 Value ranges per indicator
SELECT 'maddison' AS source, indicator_code,
  MIN(value) AS min_value, MAX(value) AS max_value,
  SUM(value < 0) AS n_negative,
  0 AS n_pct_outside_0_100
FROM stg_maddison
GROUP BY indicator_code
UNION ALL
SELECT 'wdi', indicator_code,
  MIN(value), MAX(value),
  SUM(value < 0),
  SUM(indicator_code LIKE '%.ZS' AND (value < 0 OR value > 100))
FROM stg_wdi
GROUP BY indicator_code
ORDER BY source, indicator_code;

-- 5.5 Manufacturing has to be part of industry
SELECT COUNT(*) AS n_country_years_compared,
  SUM(mf.value > ind.value) AS n_manufacturing_gt_industry
FROM stg_wdi mf
JOIN stg_wdi ind
  ON ind.country_iso3 = mf.country_iso3
  AND ind.year = mf.year
  AND ind.indicator_code = 'NV.IND.TOTL.ZS'
WHERE mf.indicator_code = 'NV.IND.MANF.ZS';

-- 5.6 Checks whether sector shares add up to 100%
WITH s AS (
  SELECT country_iso3, year,
    MAX(CASE WHEN indicator_code = 'NV.AGR.TOTL.ZS' THEN value END) AS va_agr,
    MAX(CASE WHEN indicator_code = 'NV.IND.TOTL.ZS' THEN value END) AS va_ind,
    MAX(CASE WHEN indicator_code = 'NV.SRV.TOTL.ZS' THEN value END) AS va_srv,
    MAX(CASE WHEN indicator_code = 'SL.AGR.EMPL.ZS' THEN value END) AS em_agr,
    MAX(CASE WHEN indicator_code = 'SL.IND.EMPL.ZS' THEN value END) AS em_ind,
    MAX(CASE WHEN indicator_code = 'SL.SRV.EMPL.ZS' THEN value END) AS em_srv
  FROM stg_wdi
  GROUP BY country_iso3, year
)
SELECT country_iso3,
  ROUND(AVG(va_agr + va_ind + va_srv), 1) AS avg_value_added_sum,
  ROUND(MIN(va_agr + va_ind + va_srv), 1) AS min_value_added_sum,
  ROUND(MAX(va_agr + va_ind + va_srv), 1) AS max_value_added_sum,
  ROUND(AVG(em_agr + em_ind + em_srv), 1) AS avg_employment_sum
FROM s
GROUP BY country_iso3
ORDER BY country_iso3;

-- >>> Section 6 - Historical events profile <<<

-- 6.1 Events per category
SELECT category, COUNT(*) AS n_events
FROM stg_events
GROUP BY category
ORDER BY n_events DESC;

-- 6.2 Events per economic impact
SELECT economic_impact, COUNT(*) AS n_events
FROM stg_events
GROUP BY economic_impact
ORDER BY n_events DESC;

-- 6.3 Events per decade (all countries and Portugal only)
SELECT FLOOR(year / 10) * 10 AS decade,
  COUNT(*) AS n_events_all,
  SUM(country_iso3 = 'PRT') AS n_events_prt
FROM stg_events
GROUP BY decade
ORDER BY decade;

-- 6.4 Country-years with more than one event
SELECT country_iso3, year, COUNT(*) AS n_events
FROM stg_events
GROUP BY country_iso3, year
HAVING COUNT(*) > 1
ORDER BY n_events DESC, country_iso3, year;