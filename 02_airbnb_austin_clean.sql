-- ===================================================================
-- 02 Clean data – from dirty to cleaning
-- ===================================================================
-- 1.1 Backup data from original table for cleaning
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS listings_austin_original;
CREATE TABLE IF NOT EXISTS listings_austin_original AS 
(
    SELECT *
    FROM listings_austin
);

-- ===================================================================
-- 1.2 Check duplicate data
-- -------------------------------------------------------------------

-- there is 0 duplicate row
SELECT 
    COUNT(*),
    COUNT(DISTINCT id) AS unique_id,
    COUNT(DISTINCT listing_url) AS unique_url
FROM listings_austin;


-- ===================================================================
-- 1.3 Handle missing data
-- -------------------------------------------------------------------

-- there do not have missing values
SELECT 
    SUM(ISNULL(id)) AS id,
    SUM(ISNULL(listing_url)) AS listing_url,
    SUM(ISNULL(picture_url)) AS picture_url,
    SUM(ISNULL(host_id)) AS host_id, 
    SUM(ISNULL(host_name)) AS host_name, 
    SUM(ISNULL(host_since)) AS host_since, 
    SUM(ISNULL(zipcode)) AS zipcode, 
    SUM(ISNULL(latitude)) AS latitude, 
    SUM(ISNULL(longitude)) AS longitude, 
    SUM(ISNULL(property_type)) AS property_type, 
    SUM(ISNULL(room_type)) AS room_type, 
    SUM(ISNULL(accommodates)) AS accommodates, 
    SUM(ISNULL(bathrooms_text)) AS bathrooms_text, 
    SUM(ISNULL(bedrooms)) AS bedrooms, 
    SUM(ISNULL(beds)) AS beds, 
    SUM(ISNULL(price)) AS price, 
    SUM(ISNULL(minimum_nights)) AS minimum_nights, 
    SUM(ISNULL(maximum_nights)) AS maximum_nights, 
    SUM(ISNULL(availability_30)) AS availability_30, 
    SUM(ISNULL(availability_90)) AS availability_90, 
    SUM(ISNULL(availability_365)) AS availability_365, 
    SUM(ISNULL(number_of_reviews)) AS number_of_reviews, 
    SUM(ISNULL(number_of_reviews_l30d)) AS number_of_reviews_l30d, 
    SUM(ISNULL(reviews_per_month)) AS reviews_per_month, 
    SUM(ISNULL(first_review)) AS first_review, 
    SUM(ISNULL(last_review)) AS last_review, 
    SUM(ISNULL(review_scores_rating)) AS review_scores_rating, 
    SUM(ISNULL(review_scores_accuracy)) AS review_scores_accuracy, 
    SUM(ISNULL(review_scores_cleanliness)) AS review_scores_cleanliness, 
    SUM(ISNULL(review_scores_checkin)) AS review_scores_checkin, 
    SUM(ISNULL(review_scores_communication)) AS review_scores_communication, 
    SUM(ISNULL(review_scores_location)) AS review_scores_location, 
    SUM(ISNULL(review_scores_value)) AS review_scores_value, 
    SUM(ISNULL(host_listings)) AS host_listings, 
    SUM(ISNULL(host_listings_entire_homes)) AS host_listings_entire_homes, 
    SUM(ISNULL(host_listings_private_rooms)) AS host_listings_private_rooms, 
    SUM(ISNULL(host_listings_shared_rooms)) AS host_listings_shared_rooms
FROM listings_austin;


-- ===================================================================
-- 1.4 Remove irrelevant data
-- -------------------------------------------------------------------

-- check the property coordinates all in Austin area
SELECT 
    MIN(latitude), 
    MAX(latitude),
    MIN(longitude),
    MAX(longitude)
FROM listings_austin;


-- ===================================================================
-- 1.5 Check string values
-- -------------------------------------------------------------------

-- split numbers and bathrooms_type of 'bathrooms_text'
SELECT 
    bathrooms_text,
    count(*),
    SUBSTRING_INDEX(bathrooms_text, ' ', 1) AS bathrooms,
    (CASE
        WHEN bathrooms_text LIKE '%shared%' THEN 'Shared'
        ELSE 'Private'
        END) AS bathrooms_type
FROM listings_austin
GROUP BY bathrooms_text
ORDER BY bathrooms_text;

-- replace the 'half' string to 0.5 for extracting numeric values
UPDATE listings_austin 
SET 
    bathrooms_text = REPLACE(REPLACE(LOWER(bathrooms_text), 'half', '0.5'), '-', ' ')
WHERE bathrooms_text LIKE '%-%';

--  reorder string of specific rows like 'Private half-bath' and 'Shared half-bath'  
UPDATE listings_austin 
SET 
    bathrooms_text = CONCAT(SUBSTR(bathrooms_text, - 8, 3),
            ' ',
            SUBSTRING_INDEX(bathrooms_text, ' ', 1),
            ' ',
            SUBSTRING_INDEX(bathrooms_text, ' ', - 1))
WHERE
    LEFT(bathrooms_text, 1) LIKE 'p'
    OR LEFT(bathrooms_text, 1) LIKE 's';

-- update bathrooms info to split store numeric values and strings from 'bathrooms_text' column
ALTER TABLE listings_austin
-- DROP COLUMN bathrooms,
-- DROP COLUMN bathrooms_type, 
ADD COLUMN bathrooms FLOAT AFTER beds,
ADD COLUMN bathrooms_type VARCHAR(10) AFTER bathrooms;

UPDATE listings_austin 
SET 
    bathrooms = SUBSTRING_INDEX(bathrooms_text, ' ', 1),
    bathrooms_type = (CASE
        WHEN bathrooms_text LIKE '%shared%' THEN 'Shared'
        ELSE 'Private'
    END);

-- -------------------------------------------------------------------
-- concatenate 'listing_name' string for usefull meaning
-- use case statement to distinguish conditions and format strings

-- UPDATE listings_austin
ALTER TABLE listings_austin
ADD COLUMN listing_name VARCHAR(255) AFTER id;

UPDATE listings_austin 
SET 
    listing_name = CONCAT(property_type,
            ' in Austin TX · ',
            (CASE
                WHEN review_scores_rating = 0 THEN ''
                ELSE '★ '
            END),
            (CASE
                WHEN review_scores_rating = 0 THEN ''
                ELSE review_scores_rating
            END),
            (CASE
                WHEN review_scores_rating = 0 THEN ''
                WHEN review_scores_rating IN (1 , 2, 3, 4, 5) THEN '.0 · '
                ELSE ' · '
            END),
            accommodates,
            -- distinguish singular and plural strings of 'accommodates'
            (CASE
                WHEN accommodates = 1 THEN ' guest'
                ELSE ' guests'
            END),
            ' · ',
            bedrooms,
            -- distinguish singular and plural strings of 'bedroom'
            (CASE
                WHEN bedrooms <= 1 THEN ' bedroom'
                ELSE ' bedrooms'
            END),
            ' · ',
            beds,
            -- distinguish singular and plural strings of 'bed'
            (CASE
                WHEN beds <= 1 THEN ' bed'
                ELSE ' beds'
            END),
            ' · ',
            bathrooms,
            -- distinguish singular and plural strings of 'bathroom'
            (CASE
                WHEN bathrooms <= 1 THEN ' bathroom'
                ELSE ' bathrooms'
            END));


-- ===================================================================
-- 1.6 Deal with outliers and invalid data
-- -------------------------------------------------------------------

-- check the validity of 'price'
SELECT 
    MIN(price), 
    MAX(price)
FROM listings_austin;

SELECT 
    property_type,
    room_type,
    accommodates,
    bedrooms,
    bathrooms_text,
    beds,
    price
FROM listings_austin
WHERE price < 30
ORDER BY price;

-- remove the row which price < 5, it is not make sanse
DELETE FROM listings_austin 
WHERE price < 10;

-- -------------------------------------------------------------------
-- check the validity of 'host_since'
SELECT
    MIN(host_since) AS earliest_host_since,
    MAX(host_since) AS latest_fhost_since
FROM listings_austin;

-- both check the validity of 'first_review' and 'last_review'
SELECT "first_review = ' '" AS fild, COUNT(first_review) AS ct_none
FROM listings_austin
WHERE first_review = ''
UNION ALL
SELECT "last_review = ' '", COUNT(last_review)
FROM listings_austin
WHERE last_review = ''
UNION ALL
SELECT "both = ' '", COUNT(*)
FROM listings_austin
WHERE first_review = '' AND last_review = '';

-- it is make sanse when first_review = '', means no review at all
SELECT 
    MIN(first_review),
    MAX(first_review),
    MIN(last_review),
    MAX(last_review)
FROM listings_austin
WHERE 
    first_review <> '';


-- ===================================================================
-- 1.7 Do type conversion
-- -------------------------------------------------------------------

-- update filling empty values in 'first_review' and 'last_review' columns with NULL
START TRANSACTION;
UPDATE listings_austin
SET 
    first_review = nullif(first_review, ''),
    last_review = nullif(last_review, '');
-- ROLLBACK;
COMMIT;

-- convert string values to date type
START TRANSACTION;
ALTER TABLE listings_austin
MODIFY first_review DATE, 
MODIFY last_review DATE;
COMMIT;


-- ===================================================================
-- Export data to CSV file fast with command lines 
-- -------------------------------------------------------------------

SELECT 
    'id',
    'listing_name',
    'listing_url',
    'picture_url',
    'host_id',
    'host_name',
    'host_since',
    'zipcode',
    'latitude',
    'longitude',
    'property_type',
    'room_type',
    'accommodates',
    'bathrooms_text',
    'bedrooms',
    'beds',
    'bathrooms',
    'bathrooms_type',
    'price',
    'minimum_nights',
    'maximum_nights',
    'availability_30',
    'availability_90',
    'availability_365',
    'number_of_reviews',
    'number_of_reviews_l30d',
    'reviews_per_month',
    'first_review',
    'last_review',
    'review_scores_rating',
    'review_scores_accuracy',
    'review_scores_cleanliness',
    'review_scores_checkin',
    'review_scores_communication',
    'review_scores_location',
    'review_scores_value',
    'host_listings',
    'host_listings_entire_homes',
    'host_listings_private_rooms',
    'host_listings_shared_rooms'
UNION ALL 
SELECT *
FROM listings_austin 
INTO OUTFILE 'F:/CS/01_Data_analysis/03_Project/03_airbnb_austin/data/listings_austin_cleaned.csv' 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n';


-- ==============================================================================
-- Now, the data is clean, accurate, consistent, complete and ready for ANALYSIS
-- ------------------------------------------------------------------------------