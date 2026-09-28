-- NETFLIX SQL ANALYSIS
-- 05 - Business Questions
-- PostgreSQL
-- -------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------
-- Business Question 1:
-- How has the composition of Netflix's catalog changed over the years
-- between Movies and TV Shows?
-- ---------------------------------------------------------------------------------------------

SELECT
    EXTRACT(YEAR FROM date_added) AS year_added,
    COUNT(CASE WHEN "type" = 'Movie' THEN 1 END) AS movie_count,
    COUNT(CASE WHEN "type" = 'TV Show' THEN 1 END) AS tv_show_count,
    ROUND(
        COUNT(CASE WHEN "type" = 'Movie' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS movie_percentage,
    ROUND(
        COUNT(CASE WHEN "type" = 'TV Show' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS tv_show_percentage
FROM netflix_titles_clean
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY year_added;


-- ---------------------------------------------------------------------------------------------
-- Business Question 2:
-- Which content ratings are most common on Netflix,
-- and how does the rating distribution differ between Movies and TV Shows?
-- ---------------------------------------------------------------------------------------------

WITH rating_counts AS (
    SELECT
        "type",
        rating,
        COUNT(*) AS title_count
    FROM netflix_titles_clean
    WHERE rating IS NOT NULL
    GROUP BY "type", rating
)
SELECT
    "type",
    rating,
    title_count,
    ROUND(
        title_count * 100.0 /
        SUM(title_count) OVER (PARTITION BY "type"),
        2
    ) AS percentage
FROM rating_counts
ORDER BY "type", title_count DESC;


-- ---------------------------------------------------------------------------------------------
-- Business Question 3:
-- Among the top 10 countries by title associations, which countries have a relatively
-- stronger Movie presence versus TV Show presence?
-- ---------------------------------------------------------------------------------------------

WITH expanded_country AS (
    SELECT 
        TRIM(
            UNNEST(STRING_TO_ARRAY(country, ','))
        ) AS country,
        "type"
    FROM netflix_titles_clean
    WHERE country IS NOT NULL
)
SELECT 
    country,
    COUNT(CASE WHEN "type" = 'Movie' THEN 1 END) AS movie_count,
    COUNT(CASE WHEN "type" = 'TV Show' THEN 1 END) AS tv_show_count,
    COUNT(*) AS title_count,
    ROUND(
        COUNT(CASE WHEN "type" = 'Movie' THEN 1 END) * 100.0
        / COUNT(*), 2
    ) AS movie_percentage,
    ROUND(
        COUNT(CASE WHEN "type" = 'TV Show' THEN 1 END) * 100.0
        / COUNT(*), 2
    ) AS tv_show_percentage
FROM expanded_country
GROUP BY country
ORDER BY title_count DESC
LIMIT 10;


-- ---------------------------------------------------------------------------------------------
-- Business Question 4:
-- Which directors are associated with the largest number of titles in the Netflix catalog,
-- and what is the Movie/TV Show mix of their titles?
-- ---------------------------------------------------------------------------------------------

WITH expanded_director AS (
    SELECT 
        TRIM(
            UNNEST(STRING_TO_ARRAY(director, ','))
        ) AS director,
        "type"
    FROM netflix_titles_clean
    WHERE director IS NOT NULL
)
SELECT 
    director,
    COUNT(CASE WHEN "type" = 'Movie' THEN 1 END) AS movie_count,
    COUNT(CASE WHEN "type" = 'TV Show' THEN 1 END) AS tv_show_count,
    COUNT(*) AS title_count,
    ROUND(
        COUNT(CASE WHEN "type" = 'Movie' THEN 1 END) * 100.0
        / COUNT(*), 2
    ) AS movie_percentage,
    ROUND(
        COUNT(CASE WHEN "type" = 'TV Show' THEN 1 END) * 100.0
        / COUNT(*), 2
    ) AS tv_show_percentage
FROM expanded_director
GROUP BY director
ORDER BY title_count DESC, director
LIMIT 10;