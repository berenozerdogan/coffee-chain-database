# Coffee Chain Enterprise Database System

This project presents a **relational database system** designed for managing the enterprise-level operations of a coffee chain business.  
The system is fully implemented using **pure SQL** and models real-world commercial processes such as store management, employees, customers, products, inventory control, and sales transactions.

The database design is based on the **Extended Entity-Relationship (EER) model**, which is later transformed into a normalized relational schema.

---

## Project Scope

The system manages the following core business domains:

- **Geographical Structure**
  - Countries
  - Cities
  - Districts

- **Store Operations**
  - Stores
  - Employees

- **Product Management**
  - Products
  - Categories
  - Seasons

- **Inventory & Sales**
  - Inventories (weak entity)
  - Sales
  - SaleDetails
  - Payments

All entities are connected through well-defined **primary keys**, **foreign keys**, and **integrity constraints**.

---

## Database Design

###  EER Modeling
- The design process starts with an **Extended Entity-Relationship (EER) diagram**
- Weak entities (e.g. `Inventories`) are modeled using **composite primary keys**
- Sales transactions are decomposed into `Sales` and `SaleDetails` to support **multi-product sales**

###  Relational Schema
- Fully normalized relational tables
- Referential integrity enforced using:
  - `PRIMARY KEY`
  - `FOREIGN KEY`
  - `UNIQUE`
  - `CHECK` constraints

---

##  Data Integrity & Constraints

To ensure data consistency and business rule enforcement:

- Product prices and employee salaries must be greater than zero
- Stock quantities cannot be negative
- Gender values are restricted to predefined options
- Email addresses are unique
- A **trigger** automatically updates inventory levels after each sale

```sql
CREATE TRIGGER trg_StockAfterSale
ON SaleDetails
AFTER INSERT
AS
BEGIN
    UPDATE i
    SET i.StockQuantity = i.StockQuantity - ins.Quantity
    FROM Inventories i
    JOIN inserted ins ON i.ProductID = ins.ProductID
    JOIN Sales s ON s.SaleID = ins.SaleID
    WHERE i.StoreID = s.StoreID;
END;




