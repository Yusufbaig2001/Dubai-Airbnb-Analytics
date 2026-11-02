-- ============================================================
-- DUBAI AIRBNB MARKET ANALYSIS
-- SQL Portfolio Script
-- Database: dubai_airbnb
-- Main table: airbnb_monthly
-- ============================================================

CREATE DATABASE IF NOT EXISTS dubai_airbnb;
USE dubai_airbnb;

-- ============================================================
-- SECTION 1: DATA VALIDATION
-- Run these checks before interpreting the business results.
-- ============================================================

-- 1.1 Total records and distinct listings
SELECT
    COUNT(*) AS total_listing_month_records,
    COUNT(DISTINCT listing_id) AS distinct_listings,
    MIN(month_date) AS first_month,
    MAX(month_date) AS last_month
FROM airbnb_monthly;

-- 1.2 Confirm one row per listing per month
-- Expected result: no rows.
SELECT
    listing_id,
    month_date,
    COUNT(*) AS row_count
FROM airbnb_monthly
GROUP BY listing_id, month_date
HAVING COUNT(*) > 1;

-- 1.3 Check missing key fields
SELECT
    SUM(listing_id IS NULL) AS missing_listing_id,
    SUM(month_date IS NULL) AS missing_month_date,
    SUM(avg_daily_rate IS NULL) AS missing_adr,
    SUM(occupancy IS NULL) AS missing_occupancy,
    SUM(revenue IS NULL) AS missing_revenue,
    SUM(neighborhood IS NULL OR TRIM(neighborhood) = '') AS missing_neighborhood
FROM airbnb_monthly;

-- 1.4 Check occupancy and price ranges
SELECT
    MIN(occupancy) AS minimum_occupancy,
    MAX(occupancy) AS maximum_occupancy,
    MIN(avg_daily_rate) AS minimum_adr,
    MAX(avg_daily_rate) AS maximum_adr,
    MIN(revenue) AS minimum_revenue,
    MAX(revenue) AS maximum_revenue
FROM airbnb_monthly
WHERE active = TRUE;

-- 1.5 Check active/inactive record counts
SELECT
    active,
    COUNT(*) AS record_count
FROM airbnb_monthly
GROUP BY active
ORDER BY active DESC;


-- ============================================================
-- SECTION 2: BUSINESS ANALYSIS
-- ============================================================

-- ============================================================
-- QUERY 1: MONTHLY REVENUE AND AVERAGE OCCUPANCY TREND
-- Business Question:
-- How is the Dubai Airbnb market performing month by month?
-- Note: each listing-month contributes one observation.
-- ============================================================

SELECT
    DATE_FORMAT(month_date, '%Y-%m') AS month,
    COUNT(DISTINCT listing_id) AS active_listings,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage
FROM airbnb_monthly
WHERE active = TRUE
GROUP BY DATE_FORMAT(month_date, '%Y-%m')
ORDER BY month;


-- ============================================================
-- QUERY 2: SUPERHOSTS VS REGULAR HOSTS
-- Business Question:
-- Do Superhost listings perform differently from other listings?
-- First calculate one set of metrics per listing, then compare
-- the groups. Average revenue below is average total revenue
-- per listing across the available active months.
-- ============================================================

WITH listing_performance AS (
    SELECT
        listing_id,
        MAX(superhost) AS superhost,
        COUNT(*) AS active_months,
        SUM(revenue) AS listing_total_revenue,
        AVG(avg_daily_rate) AS listing_avg_adr,
        AVG(occupancy) AS listing_avg_occupancy
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY listing_id
)
SELECT
    CASE
        WHEN superhost = TRUE THEN 'Superhost'
        WHEN superhost = FALSE THEN 'Regular Host'
        ELSE 'Unknown'
    END AS host_category,
    COUNT(*) AS total_listings,
    ROUND(AVG(listing_avg_adr), 2) AS average_listing_adr,
    ROUND(AVG(listing_avg_occupancy) * 100, 2) AS average_listing_occupancy_pct,
    ROUND(SUM(listing_total_revenue), 2) AS total_revenue,
    ROUND(AVG(listing_total_revenue), 2) AS average_total_revenue_per_listing
FROM listing_performance
GROUP BY
    CASE
        WHEN superhost = TRUE THEN 'Superhost'
        WHEN superhost = FALSE THEN 'Regular Host'
        ELSE 'Unknown'
    END
ORDER BY total_revenue DESC;


-- ============================================================
-- QUERY 3: TOP 5 PROPERTY TYPES BY TOTAL REVENUE
-- Business Question:
-- Which property types generate the highest total revenue?
-- Listing-level metrics prevent longer-observed listings from
-- being counted multiple times in average ADR/occupancy.
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        property_type,
        SUM(revenue) AS listing_total_revenue,
        AVG(avg_daily_rate) AS listing_avg_adr,
        AVG(occupancy) AS listing_avg_occupancy
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY listing_id, property_type
),
property_analysis AS (
    SELECT
        property_type,
        COUNT(*) AS total_listings,
        SUM(listing_total_revenue) AS total_revenue,
        AVG(listing_avg_adr) AS average_adr_per_listing,
        AVG(listing_avg_occupancy) AS average_occupancy_per_listing
    FROM listing_metrics
    GROUP BY property_type
    HAVING COUNT(*) > 100
)
SELECT
    property_type,
    total_listings,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(average_adr_per_listing, 2) AS average_adr,
    ROUND(average_occupancy_per_listing * 100, 2) AS occupancy_percentage
FROM property_analysis
ORDER BY total_revenue DESC
LIMIT 5;


-- ============================================================
-- QUERY 4: BEDROOM COUNT VS LISTING PERFORMANCE
-- Business Question:
-- How do ADR, occupancy and revenue differ by bedroom count?
-- Each listing contributes once to the group averages.
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        bedrooms,
        SUM(revenue) AS listing_total_revenue,
        AVG(avg_daily_rate) AS listing_avg_adr,
        AVG(occupancy) AS listing_avg_occupancy
    FROM airbnb_monthly
    WHERE active = TRUE
      AND bedrooms IS NOT NULL
    GROUP BY listing_id, bedrooms
)
SELECT
    bedrooms,
    COUNT(*) AS total_listings,
    ROUND(AVG(listing_avg_adr), 2) AS average_adr_per_listing,
    ROUND(AVG(listing_avg_occupancy) * 100, 2) AS average_occupancy_pct,
    ROUND(AVG(listing_total_revenue), 2) AS average_total_revenue_per_listing,
    ROUND(SUM(listing_total_revenue), 2) AS total_revenue
FROM listing_metrics
GROUP BY bedrooms
ORDER BY bedrooms;


-- ============================================================
-- QUERY 5: MONTH-OVER-MONTH REVENUE GROWTH
-- Business Question:
-- What is the month-over-month change in total revenue?
-- LAG compares each month with the previous month present
-- in the monthly result. Check the month sequence when
-- interpreting the result: a missing month would mean the
-- previous available month, not necessarily the prior calendar month.
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(month_date, '%Y-%m') AS month,
        SUM(revenue) AS total_revenue
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY DATE_FORMAT(month_date, '%Y-%m')
),
revenue_comparison AS (
    SELECT
        month,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY month) AS previous_available_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(total_revenue, 2) AS current_month_revenue,
    ROUND(previous_available_month_revenue, 2) AS previous_available_month_revenue,
    ROUND(
        (total_revenue - previous_available_month_revenue)
        * 100.0 / NULLIF(previous_available_month_revenue, 0),
        2
    ) AS revenue_growth_percentage
FROM revenue_comparison
ORDER BY month;


-- ============================================================
-- QUERY 6: TOP 10 NEIGHBORHOODS BY TOTAL REVENUE
-- Business Question:
-- Which named neighborhoods generate the highest revenue?
-- Missing/blank neighborhood values are excluded from this
-- ranking and should be reported separately in the data checks.
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        neighborhood,
        SUM(revenue) AS listing_total_revenue,
        AVG(avg_daily_rate) AS listing_avg_adr,
        AVG(occupancy) AS listing_avg_occupancy
    FROM airbnb_monthly
    WHERE active = TRUE
      AND neighborhood IS NOT NULL
      AND TRIM(neighborhood) <> ''
    GROUP BY listing_id, neighborhood
)
SELECT
    neighborhood,
    COUNT(*) AS total_listings,
    ROUND(SUM(listing_total_revenue), 2) AS total_revenue,
    ROUND(AVG(listing_avg_adr), 2) AS average_adr_per_listing,
    ROUND(AVG(listing_avg_occupancy) * 100, 2) AS average_occupancy_pct
FROM listing_metrics
GROUP BY neighborhood
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 7: NEIGHBORHOODS RANKED BY AVERAGE OCCUPANCY
-- Business Question:
-- Which neighborhoods have the highest average listing occupancy?
-- Each listing contributes once to the neighborhood average.
-- Only neighborhoods with more than 10 listings are included.
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        neighborhood,
        AVG(occupancy) AS listing_avg_occupancy
    FROM airbnb_monthly
    WHERE active = TRUE
      AND neighborhood IS NOT NULL
      AND TRIM(neighborhood) <> ''
    GROUP BY listing_id, neighborhood
),
neighborhood_analysis AS (
    SELECT
        neighborhood,
        COUNT(*) AS total_listings,
        AVG(listing_avg_occupancy) AS avg_listing_occupancy
    FROM listing_metrics
    GROUP BY neighborhood
    HAVING COUNT(*) > 10
)
SELECT
    neighborhood,
    total_listings,
    ROUND(avg_listing_occupancy * 100, 2) AS occupancy_percentage,
    DENSE_RANK() OVER (ORDER BY avg_listing_occupancy DESC) AS occupancy_rank
FROM neighborhood_analysis
ORDER BY occupancy_rank, neighborhood;


-- ============================================================
-- QUERY 8: HOSTS GENERATING THE HIGHEST REVENUE
-- Business Question:
-- Which hosts have the highest total listing revenue?
-- Aggregate monthly rows to listing first to count each listing
-- once and calculate average listing-level ADR/occupancy.
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        host_id,
        SUM(revenue) AS listing_total_revenue,
        AVG(avg_daily_rate) AS listing_avg_adr,
        AVG(occupancy) AS listing_avg_occupancy
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY listing_id, host_id
)
SELECT
    host_id,
    COUNT(*) AS total_listings,
    ROUND(SUM(listing_total_revenue), 2) AS total_revenue,
    ROUND(AVG(listing_avg_adr), 2) AS average_adr_per_listing,
    ROUND(AVG(listing_avg_occupancy) * 100, 2) AS average_occupancy_pct
FROM listing_metrics
GROUP BY host_id
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 9: PRICE AND OCCUPANCY BY ROOM TYPE
-- Business Question:
-- How do average listing ADR and occupancy differ by room type?
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        room_type,
        SUM(revenue) AS listing_total_revenue,
        AVG(avg_daily_rate) AS listing_avg_adr,
        AVG(occupancy) AS listing_avg_occupancy
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY listing_id, room_type
)
SELECT
    room_type,
    COUNT(*) AS total_listings,
    ROUND(AVG(listing_avg_adr), 2) AS average_adr_per_listing,
    ROUND(AVG(listing_avg_occupancy) * 100, 2) AS average_occupancy_pct,
    ROUND(AVG(listing_total_revenue), 2) AS average_total_revenue_per_listing,
    ROUND(SUM(listing_total_revenue), 2) AS total_revenue
FROM listing_metrics
GROUP BY room_type
ORDER BY average_adr_per_listing DESC;


-- ============================================================
-- QUERY 10: HIGH-PRICED, LOW-OCCUPANCY LISTINGS
-- Business Question:
-- Which listings have above-average ADR but below-average occupancy?
-- The market benchmarks are calculated from listing-level averages,
-- giving each listing equal weight.
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        AVG(avg_daily_rate) AS listing_avg_adr,
        AVG(occupancy) AS listing_avg_occupancy,
        SUM(revenue) AS listing_total_revenue
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY listing_id
),
market_average AS (
    SELECT
        AVG(listing_avg_adr) AS market_avg_listing_adr,
        AVG(listing_avg_occupancy) AS market_avg_listing_occupancy
    FROM listing_metrics
)
SELECT
    l.listing_id,
    ROUND(l.listing_avg_adr, 2) AS listing_average_adr,
    ROUND(l.listing_avg_occupancy * 100, 2) AS listing_occupancy_pct,
    ROUND(l.listing_total_revenue, 2) AS listing_total_revenue,
    ROUND(m.market_avg_listing_adr, 2) AS market_avg_listing_adr,
    ROUND(m.market_avg_listing_occupancy * 100, 2) AS market_avg_listing_occupancy_pct
FROM listing_metrics l
CROSS JOIN market_average m
WHERE l.listing_avg_adr > m.market_avg_listing_adr
  AND l.listing_avg_occupancy < m.market_avg_listing_occupancy
ORDER BY l.listing_avg_adr DESC;


-- ============================================================
-- QUERY 11: MONTHLY REVENUE RANKING
-- Business Question:
-- Which months generated the highest total revenue?
-- ============================================================

WITH monthly_analysis AS (
    SELECT
        DATE_FORMAT(month_date, '%Y-%m') AS month,
        SUM(revenue) AS total_revenue
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY DATE_FORMAT(month_date, '%Y-%m')
)
SELECT
    month,
    ROUND(total_revenue, 2) AS total_revenue,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM monthly_analysis
ORDER BY revenue_rank, month;


-- ============================================================
-- QUERY 12: LISTINGS WITH THE HIGHEST OCCUPANCY
-- Business Question:
-- Which listings have the highest average occupancy?
-- Active-month count is included to show how much history
-- supports each listing's average.
-- ============================================================

SELECT
    listing_id,
    COUNT(*) AS active_month_records,
    ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage,
    ROUND(AVG(avg_daily_rate), 2) AS average_adr,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM airbnb_monthly
WHERE active = TRUE
GROUP BY listing_id
ORDER BY avg_occupancy_percentage DESC, active_month_records DESC
LIMIT 10;


-- ============================================================
-- QUERY 13: REVENUE CONTRIBUTION BY ROOM TYPE
-- Business Question:
-- What percentage of total recorded revenue comes from each room type?
-- ============================================================

WITH room_revenue AS (
    SELECT
        room_type,
        SUM(revenue) AS total_revenue
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY room_type
)
SELECT
    room_type,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(
        total_revenue * 100.0 /
        NULLIF(SUM(total_revenue) OVER (), 0),
        2
    ) AS revenue_contribution_percentage
FROM room_revenue
ORDER BY total_revenue DESC;


-- ============================================================
-- QUERY 14: LISTINGS CLASSIFIED BY OCCUPANCY PERFORMANCE
-- Business Question:
-- How can listings be grouped by their average occupancy?
-- Thresholds are analytical choices for this project:
-- High >= 70%, Medium >= 40% and < 70%, Low < 40%.
-- They are not universal hospitality industry standards.
-- ============================================================

WITH listing_performance AS (
    SELECT
        listing_id,
        COUNT(*) AS active_months,
        AVG(occupancy) AS avg_occupancy,
        AVG(avg_daily_rate) AS average_adr,
        SUM(revenue) AS total_revenue
    FROM airbnb_monthly
    WHERE active = TRUE
    GROUP BY listing_id
)
SELECT
    listing_id,
    active_months,
    ROUND(avg_occupancy * 100, 2) AS avg_occupancy_percentage,
    ROUND(average_adr, 2) AS average_adr,
    ROUND(total_revenue, 2) AS total_revenue,
    CASE
        WHEN avg_occupancy >= 0.70 THEN 'High Performer'
        WHEN avg_occupancy >= 0.40 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM listing_performance
ORDER BY avg_occupancy DESC;


-- ============================================================
-- QUERY 15: NEIGHBORHOODS RANKED BY AVERAGE ADR
-- Business Question:
-- Which neighborhoods have the highest average listing ADR?
-- Each listing contributes once to the neighborhood average.
-- Only neighborhoods with more than 10 listings are included.
-- ============================================================

WITH listing_metrics AS (
    SELECT
        listing_id,
        neighborhood,
        AVG(avg_daily_rate) AS listing_avg_adr
    FROM airbnb_monthly
    WHERE active = TRUE
      AND neighborhood IS NOT NULL
      AND TRIM(neighborhood) <> ''
    GROUP BY listing_id, neighborhood
),
neighborhood_adr AS (
    SELECT
        neighborhood,
        COUNT(*) AS total_listings,
        AVG(listing_avg_adr) AS average_adr
    FROM listing_metrics
    GROUP BY neighborhood
    HAVING COUNT(*) > 10
)
SELECT
    neighborhood,
    total_listings,
    ROUND(average_adr, 2) AS average_adr,
    DENSE_RANK() OVER (ORDER BY average_adr DESC) AS adr_rank
FROM neighborhood_adr
ORDER BY adr_rank, neighborhood;


-- ============================================================
-- SECTION 3: INTERPRETATION AND LIMITATIONS
-- ============================================================
-- 1. Revenue is summed from the existing revenue column. Confirm
--    its formula and time period in the Python cleaning notebook.
-- 2. Monthly average occupancy is an average of listing-month
--    occupancy values; it is not weighted by available nights.
-- 3. Listing-level averages give each listing equal weight, but
--    listings may have different numbers of observed months.
-- 4. Superhost comparisons are descriptive, not causal.
-- 5. Neighborhood results exclude missing/blank neighborhood
--    values. The dataset's missing neighborhood coverage should
--    be disclosed in the README/dashboard.
-- 6. Occupancy performance thresholds are chosen for this project.
-- 7. LAG() compares the previous month in the available result set.
--    Verify that all calendar months are present before calling
--    it strictly month-over-month growth.
--
-- ============================================================
-- END OF DUBAI AIRBNB MARKET ANALYSIS
-- ============================================================
