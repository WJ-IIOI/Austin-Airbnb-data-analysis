![01_cover_new](/image/01_cover_new.jpg)
![02_summary](/image/02_summary.png)
# Austin Airbnb Data Analysis
## 1. Introduction
Welcome to my personal project focusing on _**Austin Airbnb Data Analysis**_. After the COVID-19 pandemic, the Airbnb rental market has flourished. Simultaneously, Austin's real estate market has remained highly active due to the monetary policies of the Federal Reserve. Through this project, which involves data cleaning, SQL exploration queries, Tableau dashboard visualization, I aspire to uncover valuable insights and trends in the Austin Airbnb market, fostering personal growth in data analysis and visualization techniques.

The main tools I used through this exploratory analysis project are **EXCEL**, **MySQL** and **Tableau**.
* **Data source**: [Inside Airbnb (CSV file)](http://insideairbnb.com/get-the-data)
* **SQL queries**: MySQLWorkbench
  * [01 Data import](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/01_airbnb_austin_import.sql)
  * [02 Data cleaning](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/02_airbnb_austin_clean.sql)
  * [03 Data anylysis](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/03_airbnb_austin_analyze.sql)
* **Tableau Dashboard**: [Tableau public](https://public.tableau.com/app/profile/jia.wang3280/viz/AustinAirbnbDashboard/Dashboard)
![03_listings](/image/03_listings.png)

## 2. Cleaning data
Using MySQL to deal with data from dirty to clean:
* 2.1. Backup data for cleaning
* 2.2. Remove duplicate data
* 2.3. Handle missing data
* 2.4. Remove irrelevant data
* 2.5. Deal with outliers and invalid data
* 2.6. Check string values
```sql
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

```
* 2.7. Do type conversion
* 2.8. Export data to CSV file for visualization

**MySQL**: [01 Data import](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/01_airbnb_austin_import.sql), [02 Data cleaning](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/02_airbnb_austin_clean.sql)
## 3. Exploring data
* 3.1 Calculate min, max, average price and distribution by room type
```sql
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
```
<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/31.png" alt=3.1 width="600" align="center"> 

* 3.2 Calculate distribution of price range
```sql
SELECT
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
GROUP BY price_range
ORDER BY count DESC;
```
![3.2](/image/32.png)

* 3.3 Calculate bedrooms distribution
```sql
SELECT 
    bedrooms,
    count(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution,
    ROUND(AVG(price)) AS avg_price
FROM listings_austin
GROUP BY bedrooms
ORDER BY bedrooms;
```

* 3.4 Calculate bathrooms distribution
```sql
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
```

* 3.5 Filter the top 10 most popular guests capacity
```sql
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
```
<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/33.png" alt=3.5 width="500" align="center"> 

* 3.6 Filter the top 10 popular places with most reviews
```sql
SELECT 
    listing_name,
    number_of_reviews AS reviews,
    price,
    host_name,
    zipcode
FROM listings_austin
ORDER BY number_of_reviews DESC
LIMIT 10;
```
<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/36.png" alt=3.6 width="800" align="center"> 

* 3.7 Calculate average price and distribution percentage by zipcode
```sql
SELECT 
    zipcode,
    round(AVG(price), 2) AS avg_price,
    COUNT(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM listings_austin)) * 100, 2) AS pct_distribution
FROM listings_austin
GROUP BY zipcode
ORDER BY count DESC;
```
<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/37.png" alt=3.7 width="400" align="center"> 

* 3.8 Calculate hosts distribution by host_since_year
```sql
SELECT
    year(host_since) AS since_year,
    COUNT(DISTINCT host_id) AS no_hosts,
    round(AVG(price), 2) AS avg_price,
    ROUND((COUNT(DISTINCT host_id) / (SELECT COUNT(DISTINCT host_id) FROM listings_austin)) * 100, 2) AS pct_distribution
FROM listings_austin
GROUP BY since_year
ORDER BY since_year;
```
<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/38.png" alt=3.8 width="900" align="center"> 

* 3.9 Calculate distribution of multiple listings and single listing
```sql
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
```
<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/39.png" alt=3.9 width="500" align="center"> 

* Calculate top 10 listings hosts
```sql
SELECT 
    RANK() OVER(ORDER BY count(*) DESC) AS ranking,
    host_name,
    host_listings,
    host_listings_entire_homes,
    host_listings_private_rooms,
    host_listings_shared_rooms,
    COUNT(*) AS count
FROM listings_austin
GROUP BY 
    host_name,
    host_listings,
    host_listings_entire_homes,
    host_listings_private_rooms,
    host_listings_shared_rooms
ORDER BY host_listings DESC
LIMIT 10;
```
<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/310.png" alt=3.10 width="900" align="center"> 

**MySQL**: [03 Data anylysis](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/03_airbnb_austin_analyze.sql)

## 4. Tableau data analysis dashboard
![03_listings](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/03_listings.png)
![04_hosts](https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/04_hosts.png)

<img src="https://github.com/WJ-IIOI/Austin-Airbnb-data-analysis/blob/main/image/05_zoom%20in.png" alt=05_zoom width="600" align="center"> 

在数据清洗完成后，我们就可以开始对数据进行可视化分析。该阶段主要是对数据做一个探索性分析并将结果可视化呈现，帮助人们更好、更直观的认识数据，把隐藏在大量数据背后的信息集中和提炼出来。本文主要对二手房房源的总价、单价、面积、户型、地区等属性进行了分析。


## 5. Contact info
Thank you for your time to review my project! 
* **Tableau Public**: [Tableau Public Profile](https://public.tableau.com/app/profile/jia.wang3280/vizzes)
* **Linkedln**: [Jia Wang Data Analyst](https://www.linkedin.com/in/jiawang-data-analyst/)
* **Website**: 
