/*
===============================================================================
Data Validation & Consistency Checks
===============================================================================
Purpose:
    This script runs a series of validation checks against the 'silver' schema
    to confirm the data is clean, consistent, and properly standardized. It
    covers:
    - Primary keys that are missing or repeated.
    - Leading/trailing whitespace in text columns.
    - Consistent, standardized category values.
    - Dates that fall outside a valid range or are out of sequence.
    - Cross-field consistency (e.g., sales = quantity * price).

How to Use:
    - Run these checks once the Silver Layer has finished loading.
    - Review and fix any rows a check returns.
===============================================================================
*/

-- ====================================================================
-- silver.crm_cust_info
-- ====================================================================
-- Find missing or repeated primary keys
-- Expected: 0 rows
WITH cust_key_counts AS (
    SELECT
        cst_id,
        COUNT(*) OVER (PARTITION BY cst_id) AS id_occurrences
    FROM silver.crm_cust_info
)
SELECT DISTINCT cst_id, id_occurrences
FROM cust_key_counts
WHERE id_occurrences > 1 OR cst_id IS NULL;

-- Find values with leading/trailing whitespace
-- Expected: 0 rows
SELECT cst_key
FROM silver.crm_cust_info
WHERE LEN(cst_key) <> LEN(LTRIM(RTRIM(cst_key)));

-- Review distinct values for standardization
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

-- ====================================================================
-- silver.crm_prd_info
-- ====================================================================
-- Find missing or repeated primary keys
-- Expected: 0 rows
WITH prd_key_counts AS (
    SELECT
        prd_id,
        COUNT(*) OVER (PARTITION BY prd_id) AS id_occurrences
    FROM silver.crm_prd_info
)
SELECT DISTINCT prd_id, id_occurrences
FROM prd_key_counts
WHERE id_occurrences > 1 OR prd_id IS NULL;

-- Find values with leading/trailing whitespace
-- Expected: 0 rows
SELECT prd_nm
FROM silver.crm_prd_info
WHERE LEN(prd_nm) <> LEN(LTRIM(RTRIM(prd_nm)));

-- Find missing or negative cost values
-- Expected: 0 rows
SELECT prd_cost
FROM silver.crm_prd_info
WHERE ISNULL(prd_cost, -1) < 0;

-- Review distinct values for standardization
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Find records where the start date is later than the end date
-- Expected: 0 rows
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- ====================================================================
-- silver.crm_sales_details
-- ====================================================================
-- Find malformed due dates
-- Expected: 0 invalid dates
SELECT
    CASE WHEN sls_due_dt = 0 THEN NULL ELSE sls_due_dt END AS sls_due_dt
FROM bronze.crm_sales_details
WHERE LEN(sls_due_dt) <> 8
   OR sls_due_dt NOT BETWEEN 19000101 AND 20500101;

-- Find records where the order date comes after the ship or due date
-- Expected: 0 rows
SELECT *
FROM silver.crm_sales_details
WHERE NOT (sls_order_dt <= sls_ship_dt AND sls_order_dt <= sls_due_dt);

-- Confirm sales amount equals quantity times price
-- Expected: 0 rows
SELECT DISTINCT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE COALESCE(sls_sales, -1) <= 0
   OR COALESCE(sls_quantity, -1) <= 0
   OR COALESCE(sls_price, -1) <= 0
   OR sls_sales <> sls_quantity * sls_price
ORDER BY sls_sales, sls_quantity, sls_price;

-- ====================================================================
-- silver.erp_cust_az12
-- ====================================================================
-- Find birthdates outside the acceptable range
-- Expected: dates between 1924-01-01 and today
SELECT DISTINCT bdate
FROM silver.erp_cust_az12
WHERE bdate NOT BETWEEN '1924-01-01' AND CAST(GETDATE() AS DATE);

-- Review distinct values for standardization
SELECT DISTINCT gen
FROM silver.erp_cust_az12;

-- ====================================================================
-- silver.erp_loc_a101
-- ====================================================================
-- Review distinct values for standardization
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ====================================================================
-- silver.erp_px_cat_g1v2
-- ====================================================================
-- Find values with leading/trailing whitespace
-- Expected: 0 rows
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE LEN(cat) <> LEN(LTRIM(RTRIM(cat)))
   OR LEN(subcat) <> LEN(LTRIM(RTRIM(subcat)))
   OR LEN(maintenance) <> LEN(LTRIM(RTRIM(maintenance)));

-- Review distinct values for standardization
SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;
