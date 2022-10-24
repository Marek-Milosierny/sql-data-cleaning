--------------------
-- Complementing missing addresses
    -- looking for NULL in property_address
select parcel_id, property_address from housing_data
where property_address IS NULL;

    -- checking matching parcel_id for addresses with NULL
SELECT a.unique_id, a.parcel_id, a.property_address, b.parcel_id, b.property_address, coalesce(a.property_address, b.property_address)
FROM housing_data a
JOIN housing_data b
    ON a.parcel_id = b.parcel_id AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL;

    -- changing NULL to address with the same parcel_id
WITH addresses as (
    SELECT a.unique_id AS id, coalesce(a.property_address, b.property_address) as address
    FROM housing_data a
    JOIN housing_data b
    ON a.parcel_id = b.parcel_id AND a.unique_id <> b.unique_id
    WHERE a.property_address IS NULL
)
UPDATE housing_data
    SET property_address = addresses.address
FROM addresses
    WHERE unique_id = addresses.id;
--------------------
-- Breaking property_address to individual columns (address, city) with substring

SELECT property_address, substring(property_address, 1, position(',' in property_address) -1) AS address,
    substring(property_address, position(',' in property_address) +1, length(property_address)) AS city
FROM housing_data;
    --creating columns for split address
ALTER TABLE housing_data
ADD property_split_address text,
ADD property_split_city text;

UPDATE housing_data
SET property_split_address = substring(property_address, 1, position(',' in property_address) -1),
    property_split_city = substring(property_address, position(',' in property_address) +1, length(property_address));
--------------------
-- Breaking owner_address to individual columns (address, city, state) with split_part

SELECT owner_address,
       split_part(owner_address, ',', 1) AS owner_split_addres,
       split_part(owner_address, ',', 2) AS owner_split_city,
       split_part(owner_address, ',', 3) AS owner_split_state
FROM housing_data;
    --creating columns for split address
ALTER TABLE housing_data
ADD owner_split_address text,
ADD owner_split_city text,
ADD owner_split_state text;

UPDATE housing_data
SET owner_split_address = split_part(owner_address, ',', 1),
    owner_split_city = split_part(owner_address, ',', 2),
    owner_split_state = split_part(owner_address, ',', 3);
--------------------
-- Changing Y and N to Yes and No in sold_as_vacant

SELECT sold_as_vacant, count(sold_as_vacant)
FROM housing_data
GROUP BY sold_as_vacant
ORDER BY 2;

SELECT sold_as_vacant,
       CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
            WHEN sold_as_vacant = 'N' THEN  'No'
            ELSE sold_as_vacant
            END
FROM housing_data;

UPDATE housing_data
SET sold_as_vacant = CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
            WHEN sold_as_vacant = 'N' THEN  'No'
            ELSE sold_as_vacant
            END;

-- Remove duplicates
    --looking for id duplicates
SELECT unique_id, count(*) FROM housing_data
GROUP BY unique_id
HAVING COUNT(*) > 1;

    --looking for duplicates from chosen columns where entries are the same
WITH row_duplicates AS(
    SELECT *, row_number() over (
    partition by parcel_id, property_address, sale_price, sale_date, legal_reference
    ORDER BY unique_id
    ) AS row_num
    FROM housing_data
)
SELECT * FROM row_duplicates
WHERE row_num > 1;

    --deleting duplicates
WITH row_duplicates AS(
    SELECT *, row_number() over (
    partition by parcel_id, property_address, sale_price, sale_date, legal_reference
    ORDER BY unique_id
    ) AS row_num
    FROM housing_data
)
DELETE FROM housing_data
WHERE unique_id IN (SELECT unique_id FROM row_duplicates
WHERE row_num > 1);
--------------------
-- Delete unused columns

ALTER TABLE housing_data
DROP COLUMN property_address,
DROP COLUMN owner_address,
DROP COLUMN tax_district;
--------------------
-- Changing columns names

ALTER TABLE housing_data
RENAME property_split_address TO property_address;

ALTER TABLE housing_data
RENAME property_split_city TO property_city;

ALTER TABLE housing_data
RENAME owner_split_address TO owner_address;

ALTER TABLE housing_data
RENAME owner_split_city TO owner_city;

ALTER TABLE housing_data
RENAME owner_split_state TO owner_state;