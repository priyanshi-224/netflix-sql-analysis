
-- NETFLIX SQL ANALYSIS
-- 04 - Advanced Analysis
-- PostgreSQL
-- -------------------------------------------------------------------


-- ---------------------------------------------------------------------------------------------
-- Advanced Analysis 1:
-- Which years had the highest number of Movies and TV Shows added to the Netflix catalog,
-- and how do those years rank within each content type?
-- ---------------------------------------------------------------------------------------------

WITH yearly_additions AS (
    SELECT
        EXTRACT(YEAR FROM date_added) AS year_added,
        "type",
        COUNT(*) AS title_count
    FROM netflix_titles_clean
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added), "type"
)
SELECT 
    year_added,
    "type",
    title_count,
    RANK() OVER (
        PARTITION BY "type"
        ORDER BY title_count DESC
    ) AS year_rank
FROM yearly_additions
ORDER BY "type", year_rank;


-- ---------------------------------------------------------------------------------------------
-- Advanced Analysis 2:
-- How long after a title's original release was it added to Netflix,
-- and does this differ between Movies and TV Shows?
-- ---------------------------------------------------------------------------------------------

WITH year_extraction AS (
    SELECT
        EXTRACT(YEAR FROM date_added) AS year_added,
        release_year,
        "type"
    FROM netflix_titles_clean
    WHERE date_added IS NOT NULL
)
SELECT
    "type",
    AVG(year_added - release_year) AS avg_difference
FROM year_extraction
GROUP BY "type";


-- ---------------------------------------------------------------------------------------------
-- Advanced Analysis 3:
-- Which genres are most common on Netflix, and does the genre mix differ between Movies and TV Shows?
-- ---------------------------------------------------------------------------------------------

WITH expanded_genre AS(
SELECT
      "type",
      TRIM(
          UNNEST(STRING_TO_ARRAY(listed_in, ','))
      ) AS genre
FROM netflix_titles_clean
WHERE listed_in IS NOT NULL
)
SELECT
      "type",
      genre,
      COUNT(*) AS title_count
FROM expanded_genre
GROUP BY "type", genre
ORDER BY "type", title_count DESC;


-- ---------------------------------------------------------------------------------------------
-- Advanced Analysis 4:
-- What share of titles were added to Netflix 10 or more years after their original release,
-- and does this differ between Movies and TV Shows?
-- ---------------------------------------------------------------------------------------------

WITH title_gap AS (
    SELECT
        "type",
        EXTRACT(YEAR FROM date_added) - release_year AS gap_years
    FROM netflix_titles_clean
    WHERE date_added IS NOT NULL
)
SELECT
    "type",
    COUNT(*) AS total_titles,
    COUNT(
        CASE
            WHEN gap_years >= 10 THEN 1
        END
    ) AS title_added_after_10_years,
    ROUND(
        COUNT(
            CASE
                WHEN gap_years >= 10 THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS percentage_after_10_years
FROM title_gap
GROUP BY "type"
ORDER BY "type";