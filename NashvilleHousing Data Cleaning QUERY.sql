-- CLEANING DATA IN SQL QUERIES --


--The Data we will be using --
SELECT *
FROM PortfolioProject..NashvilleHousing;






---------------------------------------------------------------------------------------------------------------------------------------------

-- Convert Date Format --

Select SaleDate, CONVERT(date, SaleDate)
FROM PortfolioProject..NashvilleHousing;

--UPDATE NashvilleHousing
--SET SaleDate = CONVERT(date, SaleDate);

-- OR --

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate);

--Note that there is now the SaleDateConverted Column and the SaleDate Column. For EDA, use SaleDateConverted. 









-------------------------------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address --


Select *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL;  -- The property address will NEVER change, therefore, we need to find a data source where we will reference the Address and find it


Select *                                  -- Investigating Data for Above--
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT ParcelID, PropertyAddress, COUNT(*) AS NumberOfDuplicates  --- This checks for any duplicates in the ParcelID and Address
FROM PortfolioProject..NashvilleHousing
GROUP BY ParcelID, PropertyAddress
HAVING COUNT(*) > 1

-- From teh investigations, we have found that there is a total dependance between the ParcelID and the Address. Therefore...
-- ... for any address which is NULL, we can Populate it with an address which matches a PARCELID of another ROW. Even vice...
-- ... versa. If there is a NULL ParcelID, we can fill it with the matching ID for another Address which has the same Address. 



SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- above we are joing the table on itseld whee the Parcel IDs match but where teh UNIQUE ID is not the same and where there is a null Property Address.

UPDATE a                      -- The below Query is populating the NULL Property Addresses with the Ones Matching its ParcelID
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM PortfolioProject..NashvilleHousing a
	JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
	WHERE a.PropertyAddress IS NULL;








-------------------------------------------------------------------------------------------------------------------------------------------------
-- Breaking Out Property Address to (Address, City, State) --


SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing;


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, -- CHARINDEX(',', PropertyAddress),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing -- This QUERY splits the address into different Parts using the SUBSTRING Query.





ALTER TABLE PortfolioProject..NashvilleHousing  -- Now updating the NashvilleHousing Table using the next two queries to add the parts of the PROPERTYADDRESS addresses
ADD PropertySplitAddress NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);





ALTER TABLE PortfolioProject..NashvilleHousing    -- Now updating the NashvilleHousing Table using the next two queries to add the parts of the PROPERTYADDRESS city
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));


SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing;


-- We will use the below to split the Owner Address --

SELECT -- This is an easier method to sepearate strings seperated bya comma. But the PARSENAME using periods instead of commas, 
PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
FROM PortfolioProject..NashvilleHousing






ALTER TABLE PortfolioProject..NashvilleHousing  -- Now updating the NashvilleHousing Table using the next two queries to add the parts of the OWNERADDRESS addresses
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3);






ALTER TABLE PortfolioProject..NashvilleHousing  -- Now updating the NashvilleHousing Table using the next two queries to add the parts of the OWNERADDRESS CITY
ADD OwnerSplitCity NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2);







ALTER TABLE PortfolioProject..NashvilleHousing  -- Now updating the NashvilleHousing Table using the next two queries to add the parts of the OWNERADDRESS STATE
ADD OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1);









-------------------------------------------------------------------------------------------------------------------------------------------------
-- Changing Y and N to Yes and No in SoldAsVacant Column --

-- After further investigations of the Data, it was realised that some of the DATA is inconsistent, It should eitehr (yes or no) OR (Y or N)
-- ... the below will show this and also show which of these is majority used. 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;     -- therefore from teh QUERY, it is noticed that there is more of (Yes or No) than (Y or N), therefore we will change 
				-- ... all (Y OR N) to (YES or No)


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject..NashvilleHousing;


UPDATE NashvilleHousing
SET
SoldAsVacant =  CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
					 WHEN SoldAsVacant = 'N' THEN 'No'
					 ELSE SoldAsVacant
					 END
FROM PortfolioProject..NashvilleHousing;












-------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates --



WITH row_num_cte AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
				 UniqueID) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID)
)
DELETE 
FROM row_num_cte
WHERE row_num > 1;
--ORDER BY PropertyAddress;
















-------------------------------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns -- (Dont do this to RAW Data, NOT GOOD PRACTICE TO DELETE ANY DATA)


ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

--ALTER TABLE PortfolioProject..NashvilleHousing
--DROP COLUMN SaleDate




-- NOTE THE REASON FOR DATA CLEANING --

-- The main purpose for Data cleaning is to make data usable for EDA or VIEWS or any manipulation such as...
-- ... Duplicates, Checking If Data says its what it is, A standard Form of data on each Row such as the...
-- ... Yes No thing or Date formats, NULL values that can be populated via any reference from Data inside

-- Another important thing to Note is that you should make deleting Duplicates the Last thing, and also you should...
-- ... NEVER delete ANY RAW DATA. This is not GOOD practice.

-- When it comes to NULL Values, one should always strive to Populate the NULLs with Accurate Data they can...
-- ... find before assigning a VALUE to them. They could also use a statement such as 'NO Value' instead of an...
-- ... actual Value