
-- NETFLIX SQL ANALYSIS
-- 01 - Database Setup
-- PostgreSQL
-- ----------------------------------------------------------------

-- Raw table
-- Purpose: Store the original CSV data without transformations.
-- Cleaning and transformations are performed separately.

CREATE TABLE netflix_titles_raw (
    show_id TEXT,
    type TEXT,
    title TEXT,
    director TEXT,
    cast TEXT,
    country TEXT,
    date_added TEXT,
    release_year INTEGER,
    rating TEXT,
    duration TEXT,
    listed_in TEXT,
    description TEXT
);