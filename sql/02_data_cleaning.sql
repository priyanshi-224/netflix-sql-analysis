
-- Netflix SQL Analysis
-- 02 - Data Cleaning & Transformation
-- PostgreSQL
-- ---------------------------------------------------------------

-- Create a cleaned analytical table from the raw source table.
-- The raw table is preserved unchanged.

DROP TABLE IF EXISTS netflix_titles_clean;

CREATE TABLE netflix_titles_clean AS
SELECT
    show_id,
    type,
    title,
    director,
    cast,
    country,
    TO_DATE(date_added, 'Month DD, YYYY') AS date_added,
    release_year,
    rating,
    duration,
    listed_in,
    description
FROM netflix_titles_raw;


-- ------------------------------------------------------------
-- Duration transformation
-- Extract numeric duration and standardize the unit.
-- Movies are measured in minutes.
-- TV Shows are measured in seasons.
-- ------------------------------------------------------------

ALTER TABLE netflix_titles_clean
ADD COLUMN duration_value INTEGER,
ADD COLUMN duration_unit TEXT;

UPDATE netflix_titles_clean
SET
    duration_value = SPLIT_PART(duration, ' ', 1)::INTEGER,
    duration_unit = CASE
        WHEN SPLIT_PART(duration, ' ', 2) = 'min' THEN 'min'
        WHEN SPLIT_PART(duration, ' ', 2) IN ('Season', 'Seasons') THEN 'season'
    END;


-- ------------------------------------------------------------
-- Rating data quality correction
-- Three records contain duration-like values in the rating
-- field. Since the correct rating cannot be inferred safely,
-- these values are converted to NULL rather than fabricated.
-- ------------------------------------------------------------

UPDATE netflix_titles_clean
SET rating = NULL
WHERE rating IN ('66 min', '74 min', '84 min');


-- ------------------------------------------------------------
-- Validation
-- ------------------------------------------------------------

-- Confirm that cleaning did not remove records.
SELECT
    (SELECT COUNT(*) FROM netflix_titles_raw) AS raw_rows,
    (SELECT COUNT(*) FROM netflix_titles_clean) AS clean_rows;

-- Confirm invalid rating values no longer exist.
SELECT COUNT(*) AS invalid_rating_count
FROM netflix_titles_clean
WHERE rating IN ('66 min', '74 min', '84 min');

-- Confirm missing date_added values are retained rather than
-- incorrectly inferred.
SELECT COUNT(*) AS null_date_added
FROM netflix_titles_clean
WHERE date_added IS NULL;