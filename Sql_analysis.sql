create database dubai_airbnb;
use dubai_airbnb;

select * from airbnb_monthly;
-- =====================================================
-- DUBAI AIRBNB MARKET ANALYSIS
-- SQL PROJECT - ADVANCED QUERIES
-- Table: airbnb_monthly
-- =====================================================


-- =====================================================
-- Q1. MONTHLY REVENUE & AVERAGE OCCUPANCY TREND
-- Business Question:
-- How is the Dubai Airbnb market performing month by month?
-- Analyze total monthly revenue and average occupancy.
-- =====================================================

SELECT
    DATE_FORMAT(month_date, '%Y-%m') AS month,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage

FROM airbnb_monthly

WHERE active = TRUE

GROUP BY DATE_FORMAT(month_date, '%Y-%m')

ORDER BY month;


-- =====================================================
-- Q2. SUPERHOSTS VS REGULAR HOSTS
-- Business Question:
-- Do Superhosts perform better than Regular Hosts?
-- Compare their average daily rate (ADR),
-- average occupancy, total listings, and revenue.
-- =====================================================

SELECT
    CASE
        WHEN superhost = TRUE THEN 'Superhost'
        ELSE 'Regular Host'
    END AS host_category,

    COUNT(DISTINCT listing_id) AS total_listings,

    ROUND(AVG(avg_daily_rate), 2) AS average_adr,

    ROUND(AVG(occupancy) * 100, 2) AS average_occupancy_percentage,

    ROUND(AVG(revenue), 2) AS average_revenue

FROM airbnb_monthly

WHERE active = TRUE

GROUP BY
    CASE
        WHEN superhost = TRUE THEN 'Superhost'
        ELSE 'Regular Host'
    END

ORDER BY average_revenue DESC;


-- =====================================================
-- Q3. TOP 5 PROPERTY TYPES BY TOTAL REVENUE
-- Business Question:
-- Which are the top 5 property types generating
-- the highest total revenue in Dubai?
-- Include only property types having more than
-- 100 distinct listings.
-- =====================================================

WITH property_analysis AS (

    SELECT
        property_type,

        COUNT(DISTINCT listing_id) AS total_listings,

        SUM(revenue) AS total_revenue,

        AVG(avg_daily_rate) AS average_adr,

        AVG(occupancy) AS average_occupancy

    FROM airbnb_monthly

    WHERE active = TRUE

    GROUP BY property_type

    HAVING COUNT(DISTINCT listing_id) > 100

)

SELECT
    property_type,

    total_listings,

    ROUND(total_revenue, 2) AS total_revenue,

    ROUND(average_adr, 2) AS average_adr,

    ROUND(average_occupancy * 100, 2) AS occupancy_percentage

FROM property_analysis

ORDER BY total_revenue DESC

LIMIT 5;


-- =====================================================
-- Q4. IMPACT OF NUMBER OF BEDROOMS ON ADR
-- Business Question:
-- How does the number of bedrooms affect the
-- average daily rate (ADR) of Airbnb listings?
-- Compare ADR, occupancy, revenue, and listing count
-- across different bedroom categories.
-- =====================================================

SELECT
    bedrooms,

    COUNT(DISTINCT listing_id) AS total_listings,

    ROUND(AVG(avg_daily_rate), 2) AS average_adr,

    ROUND(AVG(occupancy) * 100, 2) AS average_occupancy,

    ROUND(AVG(revenue), 2) AS average_revenue

FROM airbnb_monthly

WHERE active = TRUE
  AND bedrooms IS NOT NULL

GROUP BY bedrooms

ORDER BY bedrooms;


-- =====================================================
-- Q5. MONTH-OVER-MONTH (MoM) REVENUE GROWTH
-- Business Question:
-- What is the month-over-month percentage growth
-- or decline in total Dubai Airbnb revenue?
-- Use CTEs and the LAG() Window Function to
-- compare current month revenue with previous month.
-- =====================================================

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

        LAG(total_revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue

    FROM monthly_revenue

)

SELECT
    month,

    ROUND(total_revenue, 2) AS current_month_revenue,

    ROUND(previous_month_revenue, 2) AS previous_month_revenue,

    ROUND(
        (
            (total_revenue - previous_month_revenue)
            / NULLIF(previous_month_revenue, 0)
        ) * 100,
        2
    ) AS revenue_growth_percentage

FROM revenue_comparison

ORDER BY month;


-- =====================================================
-- Q6. TOP 10 NEIGHBORHOODS BY TOTAL REVENUE
-- Business Question:
-- Which 10 neighborhoods generate the highest
-- total Airbnb revenue in Dubai?
-- =====================================================

SELECT
    neighborhood,
    COUNT(DISTINCT listing_id) AS total_listings,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(avg_daily_rate), 2) AS average_adr,
    ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage

FROM airbnb_monthly

WHERE active = TRUE

GROUP BY neighborhood

ORDER BY total_revenue DESC

LIMIT 10;


-- =====================================================
-- Q7. RANK NEIGHBORHOODS BY AVERAGE OCCUPANCY
-- Business Question:
-- Which Dubai neighborhoods have the highest
-- average occupancy rates?
-- Rank neighborhoods based on occupancy.
-- =====================================================

WITH neighborhood_analysis AS (

    SELECT
        neighborhood,
        COUNT(DISTINCT listing_id) AS total_listings,
        AVG(occupancy) AS avg_occupancy

    FROM airbnb_monthly

    WHERE active = TRUE

    GROUP BY neighborhood

    HAVING COUNT(DISTINCT listing_id) > 10

)

SELECT
    neighborhood,
    total_listings,

    ROUND(avg_occupancy * 100, 2) AS occupancy_percentage,

    DENSE_RANK() OVER (
        ORDER BY avg_occupancy DESC
    ) AS occupancy_rank

FROM neighborhood_analysis

ORDER BY occupancy_rank;


-- =====================================================
-- Q8. HOSTS GENERATING THE HIGHEST REVENUE
-- Business Question:
-- Who are the top 10 hosts generating the highest
-- total revenue from their Airbnb listings?
-- =====================================================

SELECT
    host_id,
    COUNT(DISTINCT listing_id) AS total_listings,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(avg_daily_rate), 2) AS average_adr,
    ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage

FROM airbnb_monthly

WHERE active = TRUE

GROUP BY host_id

ORDER BY total_revenue DESC

LIMIT 10;


-- =====================================================
-- Q9. PRICE COMPARISON BY ROOM TYPE
-- Business Question:
-- How do average daily rates and occupancy
-- differ across different room types?
-- =====================================================

SELECT
    room_type,
    COUNT(DISTINCT listing_id) AS total_listings,
    ROUND(AVG(avg_daily_rate), 2) AS average_adr,
    ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage,
    ROUND(AVG(revenue), 2) AS average_revenue

FROM airbnb_monthly

WHERE active = TRUE

GROUP BY room_type

ORDER BY average_adr DESC;


-- =====================================================
-- Q10. IDENTIFY HIGH-PRICED AND LOW-OCCUPANCY LISTINGS
-- Business Question:
-- Which listings charge above-market average prices
-- but have below-market average occupancy?
-- =====================================================

WITH market_average AS (

    SELECT
        AVG(avg_daily_rate) AS market_avg_adr,
        AVG(occupancy) AS market_avg_occupancy

    FROM airbnb_monthly

    WHERE active = TRUE

),

listing_analysis AS (

    SELECT
        listing_id,
        ROUND(AVG(avg_daily_rate), 2) AS listing_adr,
        ROUND(AVG(occupancy) * 100, 2) AS listing_occupancy

    FROM airbnb_monthly

    WHERE active = TRUE

    GROUP BY listing_id

)

SELECT
    l.listing_id,
    l.listing_adr,
    l.listing_occupancy,
    ROUND(m.market_avg_adr, 2) AS market_avg_adr,
    ROUND(m.market_avg_occupancy * 100, 2) AS market_avg_occupancy

FROM listing_analysis l

CROSS JOIN market_average m

WHERE l.listing_adr > m.market_avg_adr
  AND l.listing_occupancy < m.market_avg_occupancy

ORDER BY l.listing_adr DESC;


-- =====================================================
-- Q11. MONTHLY REVENUE RANKING
-- Business Question:
-- Rank each month based on total revenue generated.
-- Which months perform best in the Dubai Airbnb market?
-- =====================================================

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

    DENSE_RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS revenue_rank

FROM monthly_analysis

ORDER BY revenue_rank;


-- =====================================================
-- Q12. LISTINGS WITH THE HIGHEST OCCUPANCY
-- Business Question:
-- Which 10 Airbnb listings have the highest
-- average occupancy rates?
-- =====================================================

SELECT
    listing_id,
    COUNT(*) AS active_month_records,
    ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage,
    ROUND(AVG(avg_daily_rate), 2) AS average_adr,
    ROUND(SUM(revenue), 2) AS total_revenue

FROM airbnb_monthly

WHERE active = TRUE

GROUP BY listing_id

ORDER BY avg_occupancy_percentage DESC

LIMIT 10;


-- =====================================================
-- Q13. REVENUE CONTRIBUTION BY ROOM TYPE
-- Business Question:
-- What percentage of total Dubai Airbnb revenue
-- comes from each room type?
-- =====================================================

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


-- =====================================================
-- Q14. LISTINGS CLASSIFIED BY PERFORMANCE
-- Business Question:
-- Classify Airbnb listings into High, Medium,
-- and Low performers based on their average
-- occupancy rates.
-- =====================================================

WITH listing_performance AS (

    SELECT
        listing_id,
        ROUND(AVG(occupancy) * 100, 2) AS avg_occupancy_percentage,
        ROUND(AVG(avg_daily_rate), 2) AS average_adr,
        ROUND(SUM(revenue), 2) AS total_revenue

    FROM airbnb_monthly

    WHERE active = TRUE

    GROUP BY listing_id

)

SELECT
    listing_id,
    avg_occupancy_percentage,
    average_adr,
    total_revenue,

    CASE
        WHEN avg_occupancy_percentage >= 70
            THEN 'High Performer'

        WHEN avg_occupancy_percentage >= 40
            THEN 'Medium Performer'

        ELSE 'Low Performer'
    END AS performance_category

FROM listing_performance

ORDER BY avg_occupancy_percentage DESC;


-- =====================================================
-- Q15. NEIGHBORHOOD ADR RANKING
-- Business Question:
-- Rank Dubai neighborhoods based on average
-- daily rates (ADR).
-- Which neighborhoods command the highest
-- average rental prices?
-- =====================================================

WITH neighborhood_adr AS (

    SELECT
        neighborhood,
        COUNT(DISTINCT listing_id) AS total_listings,
        AVG(avg_daily_rate) AS average_adr

    FROM airbnb_monthly

    WHERE active = TRUE

    GROUP BY neighborhood

    HAVING COUNT(DISTINCT listing_id) > 10

)

SELECT
    neighborhood,
    total_listings,
    ROUND(average_adr, 2) AS average_adr,

    DENSE_RANK() OVER (
        ORDER BY average_adr DESC
    ) AS adr_rank

FROM neighborhood_adr

ORDER BY adr_rank;

-- =====================================================
-- END OF DUBAI AIRBNB MARKET ANALYSIS
-- =====================================================
