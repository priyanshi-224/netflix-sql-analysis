
-- NETFLIX SQL ANALYSIS
-- 03 - Exploratory Analysis
-- PostgreSQL
-- -------------------------------------------------------------------

-- Business Question 1
-- What is the composition of Netflix's catalog by content type?
-- -------------------------------------------------------------------

SELECT
    type,
    COUNT(*) AS type_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM netflix_titles_clean
GROUP BY type;

-- --------------------------------------------------------------------
-- Business Question 2
-- Which release years have the highest number of titles?
-- --------------------------------------------------------------------

SELECT
    release_year,
    COUNT(*) AS title_count
FROM netflix_titles_clean
GROUP BY release_year
ORDER BY title_count DESC
LIMIT 10;

-- --------------------------------------------------------------------
-- Business Question 3
-- How does the Netflix catalog vary by content type and
-- release year?
-- --------------------------------------------------------------------

SELECT
    release_year,
    type,
    COUNT(*) AS title_count
FROM netflix_titles_clean
GROUP BY release_year, type
ORDER BY release_year ASC, title_count DESC;

-- ----------------------------------------------------------------------------
-- Business Question 4
-- Within each release year, what percentage of titles were Movies vs TV Shows?
-- ----------------------------------------------------------------------------

SELECT 
    release_year,
    "type",
    COUNT(*) AS title_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (PARTITION BY release_year),
        2
    ) AS percentage
FROM netflix_titles_clean
GROUP BY release_year, "type"
ORDER BY release_year, "type";

-- ----------------------------------------------------------------------------
-- Business Question 5:
-- What is the distribution of titles across Netflix content ratings?
-- ----------------------------------------------------------------------------

SELECT 
    rating,
    COUNT(*) AS title_count,
    ROUND(
        COUNT(*) * 100.0 
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM netflix_titles_clean
GROUP BY rating
ORDER BY title_count DESC;

-- ------------------------------------------------------------------------------
-- Business Question 6:
-- How does the content rating distribution differ between Movies and TV Shows?
-- -------------------------------------------------------------------------------

SELECT 
    "type",
    rating,
    COUNT(*) AS title_count,
    ROUND(
        COUNT(*) * 100.0 
        / SUM(COUNT(*)) OVER (PARTITION BY "type"),
        2
    ) AS percentage
FROM netflix_titles_clean
GROUP BY rating, "type"
ORDER BY 
    SUM(COUNT(*)) OVER (PARTITION BY rating) DESC,
    rating,
    "type";

-- -------------------------------------------------------------------------------
-- Business Question 7:
-- How are Netflix Movies distributed across duration ranges?
-- -------------------------------------------------------------------------------

WITH movie_duration AS (
    SELECT
        CASE
            WHEN duration_value IS NULL THEN 'Unknown'
            WHEN duration_value < 60 THEN 'Under 60 minutes'
            WHEN duration_value BETWEEN 60 AND 89 THEN '60-89 minutes'
            WHEN duration_value BETWEEN 90 AND 119 THEN '90-119 minutes'
            WHEN duration_value BETWEEN 120 AND 149 THEN '120-149 minutes'
            ELSE '150+ minutes'
        END AS duration_bucket
    FROM netflix_titles_clean
    WHERE "type" = 'Movie'
)

SELECT
    duration_bucket,
    COUNT(*) AS movie_count
FROM movie_duration
GROUP BY duration_bucket
ORDER BY CASE
    WHEN duration_bucket = 'Under 60 minutes' THEN 1
    WHEN duration_bucket = '60-89 minutes' THEN 2
    WHEN duration_bucket = '90-119 minutes' THEN 3
    WHEN duration_bucket = '120-149 minutes' THEN 4
    WHEN duration_bucket = '150+ minutes' THEN 5
    ELSE 6
END;

-- ------------------------------------------------------------------------------------------
-- Business Question 8:
-- In which years did the Netflix catalog in this dataset receive the most title additions?
-- What percentage of titles with a known date_added were added in each year?
-- -------------------------------------------------------------------------------------------

SELECT
    EXTRACT(YEAR FROM date_added) AS year_added,
    COUNT(*) AS no_of_titles_added,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM netflix_titles_clean
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY EXTRACT(YEAR FROM date_added);

-- ---------------------------------------------------------------------------------------------
-- Business Question 9:
-- Which countries contribute the most titles to the
-- Netflix catalog in this dataset?
-- ---------------------------------------------------------------------------------------------

WITH expanded_country AS (
    SELECT
        TRIM(
            UNNEST(
                STRING_TO_ARRAY(country, ',')
            )
        ) AS country
    FROM netflix_titles_clean
    WHERE country IS NOT NULL
)
SELECT
    country,
    COUNT(*) AS title_count
FROM expanded_country
GROUP BY country
ORDER BY title_count DESC
LIMIT 10;


-- --------------------------------------------------------------------------------------------
-- Business Question 10:
-- For each release year, what are the top 3 titles alphabetically
-- within each content type?
-- --------------------------------------------------------------------------------------------

WITH ranked_titles AS (
    SELECT
        release_year,
        "type",
        title,
        ROW_NUMBER() OVER (
            PARTITION BY release_year, "type"
            ORDER BY title
        ) AS title_rank
    FROM netflix_titles_clean
)
SELECT
    release_year,
    "type",
    title,
    title_rank
FROM ranked_titles
WHERE title_rank <= 3;


-- ----------------------------------------------------------------------------------------
-- Business Question 11: 
-- How did the number of titles added to the dataset
-- change from one year to the next?
-- ---------------------------------------------------------------------------------------------

WITH yearly_additions AS (
    SELECT
        EXTRACT(YEAR FROM date_added) AS year_added,
        COUNT(*) AS title_count
    FROM netflix_titles_clean
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
),
yearly_comparison AS (
    SELECT
        year_added,
        title_count,
        LAG(title_count) OVER (
            ORDER BY year_added
        ) AS previous_year_count
    FROM yearly_additions
)
SELECT
    year_added,
    title_count,
    previous_year_count,
    title_count - previous_year_count AS change_from_previous_year,
    ROUND(
        (title_count - previous_year_count) * 100.0
        / previous_year_count,
        2
    ) AS percentage_change
FROM yearly_comparison
ORDER BY year_added;



-- ---------------------------------------------------------------------------------------------
-- Business Question 12:
-- How has the cumulative number of titles added to the dataset
-- grown over the years?
-- ---------------------------------------------------------------------------------------------

WITH yearly_additions AS (
    SELECT
        EXTRACT(YEAR FROM date_added) AS year_added,
        COUNT(*) AS title_count
    FROM netflix_titles_clean
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT
    year_added AS "year",
    title_count AS title_added,
    SUM(title_count) OVER (
        ORDER BY year_added
    ) AS cumulative_titles
FROM yearly_additions;


-- ---------------------------------------------------------------------------------------------
-- Business Question 13:
-- Which countries contribute the most Movies and TV Shows to the
-- Netflix catalog, and how does their content mix differ?
-- ---------------------------------------------------------------------------------------------

WITH expanded_country AS (
    SELECT
        TRIM(
            UNNEST(
                STRING_TO_ARRAY(country, ',')
            )
        ) AS country,
        type
    FROM netflix_titles_clean
    WHERE country IS NOT NULL
)
SELECT
    country,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movie_count,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_show_count,
    COUNT(*) AS title_count
FROM expanded_country
GROUP BY country
ORDER BY title_count DESC;
