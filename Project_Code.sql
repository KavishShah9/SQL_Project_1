USE housing;
SHOW TABLES;
SELECT *FROM housing_data;
CREATE TABLE housing_data_copy AS SELECT *FROM housing_data;
DESCRIBE housing_data;

-- -------------------------------------------------------------------------------------------------
-- Adjusting the imported field names for accuracy. 
ALTER TABLE housing_data
RENAME COLUMN ï»¿UniqueID TO UniqueID;

-- -------------------------------------------------------------------------------------------------
-- Providing appropriate data types for all the columns. 
ALTER TABLE housing_data 
MODIFY COLUMN UniqueID MEDIUMINT,
MODIFY COLUMN ParcelID VARCHAR(200),
MODIFY COLUMN LandUse VARCHAR(200),
MODIFY COLUMN PropertyAddress VARCHAR(300),
MODIFY COLUMN SalePrice INT,
MODIFY COLUMN LegalReference VARCHAR(300),
MODIFY COLUMN SoldAsVacant VARCHAR(20),
MODIFY COLUMN OwnerName VARCHAR(300),
MODIFY COLUMN OwnerAddress VARCHAR(300),
MODIFY COLUMN Acreage DECIMAL(10, 2),
MODIFY COLUMN TaxDistrict VARCHAR(300),
MODIFY COLUMN LandValue INT,
MODIFY COLUMN TotalValue INT,
MODIFY COLUMN Bedrooms TINYINT,
MODIFY COLUMN FullBath TINYINT,
MODIFY COLUMN HalfBath TINYINT;

UPDATE housing_data SET SaleDate = STR_TO_DATE('09-Apr-13', '%d-%b-%y');
ALTER TABLE housing_data 
MODIFY COLUMN SaleDate DATE;

ALTER TABLE housing_data 
MODIFY COLUMN YearBuilt INT;
-- -------------------------------------------------------------------------------------------------
-- Populating Property address

UPDATE housing_data AS a
INNER JOIN housing_data AS b ON a.ParcelId = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;
-- Now we do not have any cells in PropertyAddress that are NULL.

-- -------------------------------------------------------------------------------------------------
-- Breaking out address into Individual Columns (Address, City, State)
SELECT *FROM housing_data;

ALTER TABLE housing_data
ADD COLUMN Address VARCHAR(300),
ADD COLUMN City VARCHAR(300);

UPDATE housing_data
SET Address = SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) - 1);

UPDATE housing_data
SET City = SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) + 1, LENGTH(PropertyAddress));

-- -------------------------------------------------------------------------------------------------
-- Breaking out address into Individual Columns (Address, City, State)

SELECT OwnerAddress FROM housing_data;

ALTER TABLE housing_data
ADD COLUMN OwnerAddress_Lane VARCHAR(300),
ADD COLUMN OwnerCity VARCHAR(300),
ADD COLUMN OwnerState VARCHAR(300);

UPDATE housing_data
SET OwnerAddress_Lane = SUBSTRING(OwnerAddress, 1, LOCATE(",", OwnerAddress) - 1);

UPDATE housing_data
SET OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

UPDATE housing_data
SET OwnerState = SUBSTRING(OwnerAddress, -2, LOCATE(",", OwnerAddress));
-- -------------------------------------------------------------------------------------------------
-- Bringing uniformity in SoldAsVacant column

UPDATE housing_data
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant = "Y" THEN "Yes"
	WHEN SoldAsVacant = "N" THEN "No"
	ELSE SoldAsVacant
    END;

-- -------------------------------------------------------------------------------------------------
-- Removing Unnecessary Columns and changing columns to appropriate names

ALTER TABLE housing_data
DROP COLUMN OwnerAddress,
DROP COLUMN PropertyAddress;

ALTER TABLE housing_data
RENAME COLUMN Address TO PropertyAddress,
RENAME COLUMN City TO PropertyAddressCity;
-- -------------------------------------------------------------------------------------------------
-- Calculating Profit Percentage with respect to LandUse

SELECT LandUse, FORMAT(SUM(TotalValue), 1)  AS Buying_Price, FORMAT(SUM(SalePrice), 1) AS Selling_Price, FORMAT(SUM((SalePrice - TotalValue)), 1) AS Difference, 
((SUM(SalePrice) - SUM(TotalValue))/SUM(TotalValue))*100 AS Profit_Percentage
FROM housing_data
WHERE (TotalValue AND SalePrice) IS NOT NULL
GROUP BY LandUse
ORDER BY Profit_Percentage DESC;

-- -------------------------------------------------------------------------------------------------
-- Calculating the Average SellingPrice of Houses in accordance to the number of bedrooms
SELECT *FROM housing_data;

SELECT Bedrooms, FORMAT(AVG(SalePrice), 2)  AS Avg_Sale_Price, COUNT(*) AS Count
FROM housing_data
WHERE Bedrooms IS NOT NULL
GROUP BY Bedrooms
ORDER BY Bedrooms;

-- -------------------------------------------------------------------------------------------------
-- Calculating Top 10 Owners who made the mose profits
SELECT *FROM housing_data;

SELECT Ownername, COUNT(OwnerName) AS No_of_properties, ((SUM(SalePrice) - SUM(TotalValue))/SUM(TotalValue))*100 AS Profit_Percentage
FROM housing_data
WHERE OwnerName IS NOT NULL
GROUP BY OwnerName
ORDER BY Profit_Percentage DESC
LIMIT 10;

-- -------------------------------------------------------------------------------------------------
