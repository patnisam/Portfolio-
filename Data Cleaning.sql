SELECT *
FROM Nashville;


-----------Date

-------------Changing SaleDate(datatype:text) 'Alpha-Numeric' to Numeric(Date) Format date type

SELECT SaleDate
FROM Nashville;

-----------Extracting, Dat, Month and Year

SELECT SUBSTRING(SaleDate, 1,CHARINDEX('-',SaleDate)-1) AS Day_
FROM Nashville;

SELECT SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) AS Month_
FROM Nashville

SELECT SUBSTRING(SaleDate, 8,CHARINDEX('-',SaleDate) ) AS Year_
FROM Nashville


------Formatting : yy-mm--dd

SELECT '20' + SUBSTRING(SaleDate, 8,CHARINDEX('-',SaleDate) ) +   '-'    +      
  CASE WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Jan' THEN '01'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Feb' THEN '02'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Mar' THEN '03'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Apr' THEN '04'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'May' THEN '05'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Jun' THEN '06'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Jul' THEN '07'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Aug' THEN '08'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Sep' THEN '09'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Oct' THEN '10'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Nov' THEN '11'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Dec' THEN '12'
	   END +   '-'   +SUBSTRING(SaleDate, 1,CHARINDEX('-',SaleDate)-1)  
FROM Nashville


-------Creating new columns SaleDateNew type: text.

ALTER TABLE Nashville
ALTER COLUMN SaleDateNew Text;

------Inserting SaleDate Value.

UPDATE Nashville
SET SaleDateNew = '20'  + SUBSTRING(SaleDate, 8,CHARINDEX('-',SaleDate) ) +   '-'    +      
  CASE WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Jan' THEN  '01'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Feb' THEN  '02'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Mar' THEN  '03'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Apr' THEN  '04'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'May' THEN  '05'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Jun' THEN  '06'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Jul' THEN  '07'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Aug' THEN  '08'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Sep' THEN  '09'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Oct' THEN  '10'
	   WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Nov' THEN  '11'
       WHEN SUBSTRING(SaleDate, 4,CHARINDEX('-',SaleDate) ) = 'Dec' THEN  '12'
	   END +   '-'   +SUBSTRING(SaleDate, 1,CHARINDEX('-',SaleDate)-1)  
FROM Nashville

---Changing SaleDateNew column's datatype to VARCHAR

ALTER TABLE Nashville 
ALTER COLUMN SaleDateNew VARCHAR(MAX);

UPDATE Nashville 
SET SaleDateNew = CAST(SaleDateNew AS VARCHAR(MAX));


UPDATE Nashville
SET SaleDateNew = REPLACE(SaleDateNew, ' ', '');

--------

UPDATE Nashville
SET SaleDateUpdated = PARSE(SaleDateNew AS DATE )

SELECT SaleDateUpdated
FROM Nashville


---------------------Adding Missing Property Address.

SELECT *
FROM Nashville
ORDER BY ParcelID

SELECT A.ParcelID,
       A.PropertyAddress,
	   B.ParcelID,
	   B.PropertyAddress, 
	   ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM Nashville A
JOIN Nashville B
 ON A.ParcelID = B.ParcelID
 AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM Nashville A
JOIN Nashville B
 ON A.ParcelID = B.ParcelID
 AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL;





-------------------Splitting Address into Individual Columns (Address, City,State)

SELECT PropertyAddress
FROM Nashville

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
	   SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, LEN(PropertyAddress))AS City
FROM Nashville

ALTER TABLE Nashville
ADD PropertySplitAddress Nvarchar(255);

UPDATE Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE Nashville
ADD PropertySplitCity Nvarchar(255);

UPDATE Nashville
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, LEN(PropertyAddress))




-------------------Splitting Owner Address into Individual Columns (Address,City,State)

SELECT OwnerAddress
FROM Nashville


SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),3),
       PARSENAME(REPLACE(OwnerAddress,',','.'),2), 
	   PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM Nashville

ALTER TABLE Nashville
ADD OwnerSplitAddress Nvarchar(255);

UPDATE Nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)


ALTER TABLE Nashville
ADD OwnerSplitCity Nvarchar(255);

UPDATE Nashville
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)


ALTER TABLE Nashville
ADD OwnerSplitState Nvarchar(255);

UPDATE Nashville
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT OwnerSplitState
FROM Nashville



-------------------Changing Sold as From Binary 1 or 0 to 'Y': Yes or 'N': No 


SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM Nashville
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 0 THEN 'No'
       WHEN SoldAsVacant = 1 THEN 'Yes'
	   END
FROM Nashville

ALTER TABLE Nashville
ALTER COLUMN SoldASVacant varchar;




UPDATE Nashville
SET SoldAsVacant = CASE WHEN SoldAsVacant = 0 THEN 'N'
                   WHEN SoldAsVacant = 1 THEN 'Y'
	               END

SELECT SoldAsVacant
FROM Nashville


-------------------Removing Duplicates.

WITH RowNumCTE AS (
SELECT *,
       ROW_NUMBER() OVER (
	   PARTITION BY ParcelID,
	                PropertyAddress,
					SalePrice,
					LegalReference
					ORDER BY
					    UniqueID
						) Row_Num
FROM Nashville

)

SELECT *
FROM RowNumCTE 
WHERE Row_Num > 1
ORDER BY PropertyAddress 



---------------------------------Delete Unused Columns


SELECT*
FROM Nashville

ALTER TABLE Nashville
DROP COLUMN OwnerAddress, TaxDistrict,PropertyAddress;


ALTER TABLE Nashville
DROP COLUMN SaleDateNew;




