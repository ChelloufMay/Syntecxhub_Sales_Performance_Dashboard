# SQL Staging Data Quality Findings and Cleaning Rules

## 1. Source Table

The SQL staging table is:

`stg.Superstore_Raw`

The table contains the raw Superstore dataset imported from:

`sample_superstore(csv).csv`

The staging table is treated as the source layer and is not directly modified during cleaning.

---

# 2. Basic Validation Results

The SQL staging validation confirmed the results obtained during the Initial Data Profiling stage.

| Check | Result |
|---|---:|
| Rows | 10,194 |
| Columns | 21 |
| Exact duplicate rows | 0 |
| Missing cells | 0 |
| Unique Order IDs | 5,111 |
| Unique Customer IDs | 804 |
| Unique Product IDs | 1,862 |
| Negative Sales | 0 |
| Non-positive Quantity | 0 |
| Invalid Discount values | 0 |
| Negative Profit rows | 1,901 |
| Ship Date before Order Date | 0 |

The SQL staging results are consistent with the Python profiling baseline.

---

# 3. Transactional Grain

The dataset contains 10,194 transaction lines and 5,111 unique orders.

Multiple rows can belong to the same Order ID.

Therefore:

> The analytical fact table will preserve one row per order-product transaction line.

`Row_ID` is unique across all 10,194 records and will be used as the transaction-line identifier.

Orders must not be aggregated to one row per Order ID before constructing the fact table because doing so would remove product-level, quantity, discount, sales and profit information.

---

# 4. Customer Data Findings

There are:

- 804 unique Customer IDs
- 800 unique Customer Names

Each Customer ID consistently maps to:

- one Customer Name
- one Segment

However, the Customer Name `Harry Olson` is associated with five different Customer IDs.

Therefore:

> Customer Name must not be used as the customer key.

`Customer_ID` will remain the customer business identifier.

---

# 5. Orders with Multiple Customer IDs

Two orders were identified as containing multiple Customer IDs:

- `CA-2025-121465`
- `CA-2026-130494`

The affected transaction lines use different Customer IDs, including:

- `HO-15234`
- `HO-15233`
- `HO-15232`
- `HO-15231`

The affected records share the same Customer Name (`Harry Olson`) and other customer/location attributes.

No evidence is available to determine that one Customer ID is the correct replacement for the others.

### Cleaning Rule

The original `Customer_ID` will therefore be preserved on each transaction line.

Customer IDs will not be merged based on Customer Name.

The two affected orders will be documented as source-data relationship anomalies.

No transaction rows will be deleted.

---

# 6. Product Data Findings

There are:

- 1,862 unique Product IDs
- 1,849 unique Product Names

The investigation identified 32 Product IDs associated with two different Product Names.

For those affected Product IDs:

- Category remains consistent.
- Sub-Category remains consistent.
- Product Name is the inconsistent attribute.

There are also 17 Product Names associated with multiple Product IDs.

Therefore:

> Product Name cannot be used as a unique product identifier.

`Product_ID` will remain the product business identifier.

---

# 7. Product Name Standardization Rule

The clean product dimension will contain one row per Product ID.

For Product IDs associated with multiple Product Names:

> The canonical Product Name will be the Product Name with the highest frequency in the staging data.

This rule preserves the most frequently observed description while maintaining one product-dimension record per Product ID.

### Tie-breaking rule

If two or more Product Names have the same highest frequency for a Product ID:

> The alphabetically first trimmed Product Name will be selected as the canonical Product Name.

The original conflicting Product Names will remain available in `stg.Superstore_Raw` for traceability.

No transaction rows will be deleted.

---

# 8. Product Classification Rules

Product ID relationships with Category and Sub-Category were validated.

The profiling and SQL checks found no Product IDs associated with multiple Categories or multiple Sub-Categories.

Therefore:

`Product_ID → Category`

and

`Product_ID → Sub_Category`

are treated as consistent for the purpose of the clean analytical model.

The product hierarchy will therefore be:

Category
→ Sub-Category
→ Product

---

# 9. Order Date and Ship Date

Order Date is consistent within each Order ID.

Ship Date is also consistent within each Order ID.

No records were found where:

`Ship Date < Order Date`

Shipping duration ranges from 0 to 11 days, with an average of approximately 3.96 days.

### Cleaning Rule

- Convert `Order_Date` to SQL `DATE`.
- Convert `Ship_Date` to SQL `DATE`.
- Preserve all valid source dates.

---

# 10. Future-Dated Records

The supplied dataset contains records extending to:

- Order Date: `2026-12-30`
- Ship Date: `2027-01-05`

These dates are retained because they are part of the supplied source dataset.

The cleaning process will not remove records simply because they occur after the current system date.

Any reporting cutoff, if required later, will be treated as an explicit analytical/business rule rather than as a general data-cleaning rule.

---

# 11. Postal Code

Postal Code contains text values, including Canadian postal codes.

Therefore:

> Postal Code will be stored as a text data type.

It will not be converted to an integer because it is an identifier rather than a numerical measure.

---

# 12. Numerical Data

The numerical validation found:

- No negative Sales
- No zero or negative Quantity
- No invalid Discount values

There are 1,901 transaction lines with negative Profit.

Negative Profit is treated as a valid business outcome representing loss-making transactions.

### Cleaning Rule

Negative-profit rows will be retained.

They will not be removed or converted to positive values.

---

# 13. Missing Values and Duplicates

No missing values were found.

No exact duplicate rows were found.

### Cleaning Rule

No general missing-value imputation or duplicate-row removal is required.

Repeated Order IDs are not considered duplicate records because they represent multiple transaction lines belonging to an order.

---

# 14. Summary of Cleaning / Standardization Rules

| Area | Rule |
|---|---|
| Transaction grain | One row per order-product transaction line |
| Transaction identifier | Row_ID |
| Order ID | Preserve repeated values |
| Customer key | Customer_ID |
| Customer Name | Descriptive attribute only |
| Multi-customer orders | Preserve source Customer_ID per line; flag anomaly |
| Product key | Product_ID |
| Product Name | Descriptive attribute |
| Conflicting Product Names | Use most frequent name per Product_ID |
| Product-name tie | Alphabetically first trimmed name |
| Category | Preserve |
| Sub-Category | Preserve |
| Order Date | Convert to DATE |
| Ship Date | Convert to DATE |
| Postal Code | Store as text |
| Negative Sales | None found |
| Invalid Quantity | None found |
| Invalid Discount | None found |
| Negative Profit | Retain |
| Missing values | None found |
| Exact duplicates | None found |
| Future-dated records | Retain; no current-date filtering |

---

# 15. Modeling Implication

The cleaned analytical model will be created from `stg.Superstore_Raw`.

The staging table will remain unchanged so that the transformation process remains traceable and reproducible.

The planned analytical model will contain a central sales fact table supported by relevant dimension tables, including:

- Customer
- Product
- Geography
- Date
- Ship Mode

The fact table will preserve the original transaction-line grain.