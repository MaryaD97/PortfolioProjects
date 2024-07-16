/*
  Cleaning Data in SQL
*/

-- Initial Data Selection
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

-- Standardize Date Format

-- Set the context to the PortfolioProject database
USE PortfolioProject;
GO

-- Convert and update the SaleDate column to Date type
UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);
GO

-- Add a new column SaleDateConverted with Date type
IF COL_LENGTH('dbo.NashvilleHousing', 'SaleDateConverted') IS NULL
BEGIN
    ALTER TABLE dbo.NashvilleHousing
    ADD SaleDateConverted Date;
END
GO

-- Update the SaleDateConverted column with converted SaleDate values
UPDATE dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);
GO

-- Verify the changes
SELECT SaleDate, SaleDateConverted
FROM dbo.NashvilleHousing;

-- Populate Property Address Data

-- Select data where PropertyAddress is null, ordered by ParcelID
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID;

-- Update PropertyAddress with data from other rows with the same ParcelID
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Break out Address into Individual Columns (Address, City, State)

-- Extract Address part from PropertyAddress
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing;

-- Add and update PropertySplitAddress column
IF COL_LENGTH('dbo.NashvilleHousing', 'PropertySplitAddress') IS NULL
BEGIN
    ALTER TABLE dbo.NashvilleHousing
    ADD PropertySplitAddress NVARCHAR(255);
END
GO

UPDATE dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

-- Add and update PropertySplitCity column
IF COL_LENGTH('dbo.NashvilleHousing', 'PropertySplitCity') IS NULL
BEGIN
    ALTER TABLE dbo.NashvilleHousing
    ADD PropertySplitCity NVARCHAR(255);
END
GO

UPDATE dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Verify the changes
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

-- Extract Owner Address into Individual Columns (Address, City, State)

-- Extract parts from OwnerAddress
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PortfolioProject.dbo.NashvilleHousing;

-- Add and update OwnerSplitAddress column
IF COL_LENGTH('dbo.NashvilleHousing', 'OwnerSplitAddress') IS NULL
BEGIN
    ALTER TABLE dbo.NashvilleHousing
    ADD OwnerSplitAddress NVARCHAR(255);
END
GO

UPDATE dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

-- Add and update OwnerSplitCity column
IF COL_LENGTH('dbo.NashvilleHousing', 'OwnerSplitCity') IS NULL
BEGIN
    ALTER TABLE dbo.NashvilleHousing
    ADD OwnerSplitCity NVARCHAR(255);
END
GO

UPDATE dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

-- Add and update OwnerSplitState column
IF COL_LENGTH('dbo.NashvilleHousing', 'OwnerSplitState') IS NULL
BEGIN
    ALTER TABLE dbo.NashvilleHousing
    ADD OwnerSplitState NVARCHAR(255);
END
GO

UPDATE dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Verify the changes
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

-- Change 'Y' and 'N' to 'Yes' or 'No' in 'SoldAsVacant' Field

-- Count distinct values in SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Update SoldAsVacant to 'Yes' or 'No'
SELECT SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS SoldAsVacantStatus
FROM PortfolioProject.dbo.NashvilleHousing;

-- Remove Duplicates

WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- Delete Unused Columns

-- Select to verify columns
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

-- Drop unused columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
GO
