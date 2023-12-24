
-- ===================================================================
-- 01 create table structure
-- ===================================================================
DROP TABLE IF EXISTS listings_austin;
CREATE TABLE IF NOT EXISTS listings_austin
(
    id VARCHAR(255),
    listing_url VARCHAR(255),
    -- listing_name VARCHAR(255),
    picture_url VARCHAR(255),
    host_id INT,
    host_name VARCHAR(50),
    host_since DATE,
    zipcode INT,
    latitude DOUBLE,
    longitude DOUBLE,
    property_type VARCHAR(50),
    room_type VARCHAR(50),
    accommodates INT,
    bathrooms_text VARCHAR(50),
    bedrooms INT,
    beds INT,
    price INT,
    minimum_nights INT,
    maximum_nights INT,
    availability_30 INT,
    availability_90 INT,
    availability_365 INT,
    number_of_reviews INT,
    number_of_reviews_l30d INT,
    reviews_per_month DOUBLE,
    first_review VARCHAR(50),
    last_review VARCHAR(50),
    review_scores_rating DOUBLE,
    review_scores_accuracy DOUBLE,
    review_scores_cleanliness DOUBLE,
    review_scores_checkin DOUBLE,
    review_scores_communication DOUBLE,
    review_scores_location DOUBLE,
    review_scores_value DOUBLE,
    host_listings INT,
    host_listings_entire_homes INT,
    host_listings_private_rooms INT,
    host_listings_shared_rooms INT
);

-- import data from file
LOAD DATA INFILE 'F:/Project/airbnb_austin/data/listings_austin.csv'
INTO TABLE listings_austin
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;