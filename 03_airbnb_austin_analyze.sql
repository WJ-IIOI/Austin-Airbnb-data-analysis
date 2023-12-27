-- ===================================================================
-- 03 Analyze data
-- ===================================================================

-- 3.1 calculate min & max price, average price and distribution percentage by room type
SELECT 
    room_type,
    round(AVG(price)) AS avg_price,
    round((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution,
    COUNT(*) AS count,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM listings_austin
GROUP BY room_type
ORDER BY COUNT(*) DESC;

-- 3.2 calculate distribution of price range
SELECT 
    -- room_type,
    (CASE
        WHEN price <= 100 THEN '1 - 100'
        WHEN price > 100 AND price <= 200 THEN '100 - 200'
        WHEN price > 200 AND price <= 300 THEN '200 - 300'
        WHEN price > 300 AND price <= 400 THEN '300 - 400'
        WHEN price > 400 AND price <= 500 THEN '400 - 500'
        WHEN price > 500 AND price <= 1000 THEN '500 - 1000'
        WHEN price > 1000 AND price <= 2000 THEN '1000 - 2000'
        WHEN price > 2000 AND price <= 5000 THEN '2000 - 5000'
        ELSE '5000+'
        END
    ) AS price_range,
    COUNT(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution
FROM listings_austin
GROUP BY 
    -- room_type, 
    price_range
ORDER BY 
    -- room_type, 
    count DESC;

-- 3.3 calculate bedrooms distribution
SELECT 
    bedrooms,
    count(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution,
    ROUND(AVG(price)) AS avg_price
FROM listings_austin
GROUP BY bedrooms
ORDER BY bedrooms;

-- 3.4 calculate bathrooms distribution
-- treat half bathroom as 1 bathroom
SELECT
    (CASE
        WHEN bathrooms <= 1 THEN 1
        WHEN bathrooms > 1 AND bathrooms <= 2 THEN 2
        WHEN bathrooms > 2 AND bathrooms <= 3 THEN 3
        WHEN bathrooms > 3 AND bathrooms <= 4 THEN 4
        WHEN bathrooms > 4 AND bathrooms <= 5 THEN 5
        WHEN bathrooms > 5 AND bathrooms <= 6 THEN 6
        WHEN bathrooms > 6 AND bathrooms <= 7 THEN 7
        WHEN bathrooms > 7 AND bathrooms <= 8 THEN 8
        WHEN bathrooms > 8 AND bathrooms <= 9 THEN 9
        ELSE 10
        END
    ) AS no_bathrooms,
    count(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution,
    ROUND(AVG(price)) AS avg_price
FROM listings_austin
GROUP BY no_bathrooms
ORDER BY no_bathrooms;

-- 3.5 filter the top 10 most popular guests capacity
SELECT 
    RANK() OVER(ORDER BY count(*) DESC) AS ranking,
    accommodates AS guests,
    count(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution,
    ROUND(AVG(price)) AS avg_price
FROM listings_austin
GROUP BY guests
ORDER BY count DESC
LIMIT 10;

-- 3.6 filter the top 10 popular places with most reviews
SELECT 
    listing_name,
    number_of_reviews AS reviews,
    price,
    host_name,
    zipcode
FROM listings_austin
ORDER BY number_of_reviews DESC
LIMIT 10;

-- 3.7 calculate average price and distribution percentage by zipcode
SELECT 
    zipcode,
    round(AVG(price), 2) AS avg_price,
    COUNT(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution
FROM listings_austin
GROUP BY zipcode
ORDER BY count DESC;

-- 3.8 calculate hosts distribution by host_since_year
SELECT
    year(host_since) AS since_year,
    COUNT(DISTINCT host_id) AS no_hosts,
    round(AVG(price), 2) AS avg_price,
    ROUND((COUNT(DISTINCT host_id) / (SELECT COUNT(DISTINCT host_id) FROM listings_austin)) * 100, 2) AS pct_distribution
FROM listings_austin
GROUP BY since_year
ORDER BY since_year;

-- 3.9 calculate distribution of multiple listings and single listing 
WITH listings AS (
    SELECT 
        host_id,
        host_name,
        (CASE
            WHEN COUNT(host_id) > 1 THEN 'multi'
            ELSE 'single'
            END) AS no_listings,
        COUNT(host_id) AS count
    FROM listings_austin
    GROUP BY host_id, host_name
    ORDER BY count DESC),
total_hosts AS (
    SELECT COUNT(distinct host_id) AS total_hosts
    FROM listings_austin
    ORDER BY total_hosts DESC)
SELECT 
    no_listings,
    COUNT(host_id) AS count,
    ROUND((COUNT(host_id) / (SELECT total_hosts FROM total_hosts)) * 100, 2) AS pct_distribution
FROM listings 
GROUP BY no_listings
ORDER BY count;

-- 3.10 calculate top 10 listings hosts
SELECT 
    RANK() OVER(ORDER BY count(*) DESC) AS ranking,
    -- host_id,
    host_name,
    host_listings,
    host_listings_entire_homes,
    host_listings_private_rooms,
    host_listings_shared_rooms,
    COUNT(*) AS count
FROM listings_austin
GROUP BY 
    -- host_id, 
    host_name,
    host_listings,
    host_listings_entire_homes,
    host_listings_private_rooms,
    host_listings_shared_rooms
ORDER BY host_listings DESC
LIMIT 10;

-- ==============================================================================
-- Now, the data is ready for Visualization
-- ------------------------------------------------------------------------------