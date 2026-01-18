/* =========================================
   DATABASE RESET
   ========================================= */
USE master;
GO

IF DB_ID('CoffeeChainEnterpriseDB') IS NOT NULL
BEGIN
    ALTER DATABASE CoffeeChainEnterpriseDB
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CoffeeChainEnterpriseDB;
END;
GO

CREATE DATABASE CoffeeChainEnterpriseDB;
GO
USE CoffeeChainEnterpriseDB;
GO

/* =========================================
   MASTER TABLES
   ========================================= */
CREATE TABLE Countries (
    CountryID INT IDENTITY PRIMARY KEY,
    CountryName NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Cities (
    CityID INT IDENTITY PRIMARY KEY,
    CityName NVARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);

CREATE TABLE Districts (
    DistrictID INT IDENTITY PRIMARY KEY,
    DistrictName NVARCHAR(50) NOT NULL,
    CityID INT NOT NULL,
    FOREIGN KEY (CityID) REFERENCES Cities(CityID)
);

/* =========================================
   STORE & EMPLOYEE
   ========================================= */
CREATE TABLE Stores (
    StoreID INT IDENTITY PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    DistrictID INT NOT NULL,
    OpenDate DATE,
    StoreType NVARCHAR(20),
    FOREIGN KEY (DistrictID) REFERENCES Districts(DistrictID),
    CONSTRAINT CK_StoreType CHECK (StoreType IN ('AVM','Cadde'))
);

CREATE TABLE Employees (
    EmployeeID INT IDENTITY PRIMARY KEY,
    StoreID INT NOT NULL,
    FullName NVARCHAR(100),
    Position NVARCHAR(50),
    Salary DECIMAL(10,2),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    CONSTRAINT CK_Salary CHECK (Salary > 0)
);

/* =========================================
   PRODUCT STRUCTURE
   ========================================= */
CREATE TABLE Categories (
    CategoryID INT IDENTITY PRIMARY KEY,
    CategoryName NVARCHAR(50) UNIQUE
);

CREATE TABLE Seasons (
    SeasonID INT IDENTITY PRIMARY KEY,
    SeasonName NVARCHAR(30) UNIQUE
);

CREATE TABLE Products (
    ProductID INT IDENTITY PRIMARY KEY,
    ProductName NVARCHAR(100),
    CategoryID INT,
    SeasonID INT,
    Price DECIMAL(10,2),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    FOREIGN KEY (SeasonID) REFERENCES Seasons(SeasonID),
    CONSTRAINT CK_Price CHECK (Price > 0)
);

/* =========================================
   INVENTORY
   ========================================= */
CREATE TABLE Inventories (
    StoreID INT,
    ProductID INT,
    StockQuantity INT,
    PRIMARY KEY (StoreID, ProductID),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CK_Stock CHECK (StockQuantity >= 0)
);

/* =========================================
   CUSTOMER & SALES
   ========================================= */
CREATE TABLE Customers (
    CustomerID INT IDENTITY PRIMARY KEY,
    FullName NVARCHAR(100),
    Gender NVARCHAR(10),
    BirthDate DATE,
    Email NVARCHAR(150) UNIQUE,
    CONSTRAINT CK_Gender CHECK (Gender IN ('Male','Female','Other'))
);

CREATE TABLE Sales (
    SaleID INT IDENTITY PRIMARY KEY,
    StoreID INT,
    CustomerID INT,
    EmployeeID INT,
    SaleDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE SaleDetails (
    SaleDetailID INT IDENTITY PRIMARY KEY,
    SaleID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (SaleID) REFERENCES Sales(SaleID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Payments (
    PaymentID INT IDENTITY PRIMARY KEY,
    SaleID INT,
    Amount DECIMAL(10,2),
    PaymentMethod NVARCHAR(30),
    FOREIGN KEY (SaleID) REFERENCES Sales(SaleID),
    CONSTRAINT CK_Amount CHECK (Amount > 0)
);

/* =========================================
   TRIGGER – STOCK CONTROL
   ========================================= */
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
GO

/* =========================================
   STATIC DATA
   ========================================= */
INSERT INTO Categories VALUES
('Espresso'),('Brewed Coffee'),('Cold Brew'),('Tea'),
('Herbal Tea'),('Frappuccino'),('Cold Drinks'),
('Dessert'),('Bakery'),('Sandwich'),('Breakfast'),
('Vegan'),('Seasonal');

INSERT INTO Seasons VALUES
('Winter'),('Summer'),('Spring'),('Autumn'),('All');

INSERT INTO Countries VALUES ('Türkiye');

INSERT INTO Cities (CityName, CountryID)
VALUES
('İstanbul',1),('Ankara',1),('İzmir',1),
('Bursa',1),('Antalya',1),('Adana',1),
('Gaziantep',1);

INSERT INTO Districts (DistrictName, CityID)
SELECT d.DistrictName, c.CityID
FROM Cities c
JOIN (
    VALUES
    ('İstanbul','Kadıköy'),('İstanbul','Beşiktaş'),
    ('İstanbul','Üsküdar'),('Ankara','Çankaya'),
    ('Ankara','Keçiören'),('İzmir','Konak'),
    ('İzmir','Karşıyaka'),('Bursa','Nilüfer'),
    ('Antalya','Muratpaşa'),('Adana','Seyhan'),
    ('Gaziantep','Şahinbey')
) d(CityName, DistrictName)
ON c.CityName = d.CityName;

/* =========================================
   STORES & EMPLOYEES
   ========================================= */
INSERT INTO Stores
SELECT
    d.DistrictName + ' Store',
    d.DistrictID,
    DATEADD(DAY,-ABS(CHECKSUM(NEWID()))%3000,GETDATE()),
    CASE WHEN d.DistrictID % 2 = 0 THEN 'AVM' ELSE 'Cadde' END
FROM Districts d;

INSERT INTO Employees
SELECT
    s.StoreID,
    'Employee-' + CAST(s.StoreID AS NVARCHAR) + '-' + CAST(n AS NVARCHAR),
    CASE WHEN n=1 THEN 'Manager' ELSE 'Barista' END,
    CASE WHEN n=1 THEN 22000 ELSE 15000 END
FROM Stores s
CROSS JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) x;

/* =========================================
   PRODUCTS & INVENTORY
   ========================================= */
INSERT INTO Products
SELECT
    'Product-' + CAST(n AS NVARCHAR),
    ABS(CHECKSUM(NEWID())) % 13 + 1,
    ABS(CHECKSUM(NEWID())) % 5 + 1,
    20 + ABS(CHECKSUM(NEWID())) % 40
FROM (SELECT TOP 120 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) n FROM sys.objects) x;

INSERT INTO Inventories
SELECT s.StoreID, p.ProductID, 300 + ABS(CHECKSUM(NEWID())) % 700
FROM Stores s
CROSS JOIN Products p;

/* =========================================
   CUSTOMERS (20.000)
   ========================================= */
DECLARE @i INT = 1;
WHILE @i <= 20000
BEGIN
    INSERT INTO Customers
    VALUES (
        'Customer-' + CAST(@i AS NVARCHAR),
        CASE WHEN @i % 2 = 0 THEN 'Male' ELSE 'Female' END,
        DATEADD(YEAR,-(20+ABS(CHECKSUM(NEWID()))%40),GETDATE()),
        'customer'+CAST(@i AS NVARCHAR)+'@mail.com'
    );
    SET @i += 1;
END;

/* =========================================
   SALES (50.000)
   ========================================= */
DECLARE @s INT = 1;
DECLARE @maxStore INT = (SELECT MAX(StoreID) FROM Stores);
DECLARE @maxCust INT = (SELECT MAX(CustomerID) FROM Customers);
DECLARE @maxProd INT = (SELECT MAX(ProductID) FROM Products);

WHILE @s <= 50000
BEGIN
    DECLARE @store INT = 1 + ABS(CHECKSUM(NEWID())) % @maxStore;
    DECLARE @cust INT = 1 + ABS(CHECKSUM(NEWID())) % @maxCust;
    DECLARE @emp INT = (SELECT TOP 1 EmployeeID FROM Employees WHERE StoreID=@store);
    DECLARE @saleID INT;

    INSERT INTO Sales (StoreID,CustomerID,EmployeeID)
    VALUES (@store,@cust,@emp);

    SET @saleID = SCOPE_IDENTITY();

    DECLARE @prod INT = 1 + ABS(CHECKSUM(NEWID())) % @maxProd;

    INSERT INTO SaleDetails
    SELECT @saleID, ProductID, 1+ABS(CHECKSUM(NEWID()))%3, Price
    FROM Products WHERE ProductID=@prod;

    INSERT INTO Payments
    SELECT @saleID, SUM(Quantity*UnitPrice), 'Credit Card'
    FROM SaleDetails WHERE SaleID=@saleID;

    SET @s += 1;
END;
GO




örnek sorgular 

/* =========================================
   DATABASE RESET
   ========================================= */
USE master;
GO

IF DB_ID('CoffeeChainEnterpriseDB') IS NOT NULL
BEGIN
    ALTER DATABASE CoffeeChainEnterpriseDB
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CoffeeChainEnterpriseDB;
END;
GO

CREATE DATABASE CoffeeChainEnterpriseDB;
GO
USE CoffeeChainEnterpriseDB;
GO

/* =========================================
   MASTER TABLES
   ========================================= */
CREATE TABLE Countries (
    CountryID INT IDENTITY PRIMARY KEY,
    CountryName NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Cities (
    CityID INT IDENTITY PRIMARY KEY,
    CityName NVARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);

CREATE TABLE Districts (
    DistrictID INT IDENTITY PRIMARY KEY,
    DistrictName NVARCHAR(50) NOT NULL,
    CityID INT NOT NULL,
    FOREIGN KEY (CityID) REFERENCES Cities(CityID)
);

/* =========================================
   STORE & EMPLOYEE
   ========================================= */
CREATE TABLE Stores (
    StoreID INT IDENTITY PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    DistrictID INT NOT NULL,
    OpenDate DATE,
    StoreType NVARCHAR(20),
    FOREIGN KEY (DistrictID) REFERENCES Districts(DistrictID),
    CONSTRAINT CK_StoreType CHECK (StoreType IN ('AVM','Cadde'))
);

CREATE TABLE Employees (
    EmployeeID INT IDENTITY PRIMARY KEY,
    StoreID INT NOT NULL,
    FullName NVARCHAR(100),
    Position NVARCHAR(50),
    Salary DECIMAL(10,2),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    CONSTRAINT CK_Salary CHECK (Salary > 0)
);

/* =========================================
   PRODUCT STRUCTURE
   ========================================= */
CREATE TABLE Categories (
    CategoryID INT IDENTITY PRIMARY KEY,
    CategoryName NVARCHAR(50) UNIQUE
);

CREATE TABLE Seasons (
    SeasonID INT IDENTITY PRIMARY KEY,
    SeasonName NVARCHAR(30) UNIQUE
);

CREATE TABLE Products (
    ProductID INT IDENTITY PRIMARY KEY,
    ProductName NVARCHAR(100),
    CategoryID INT,
    SeasonID INT,
    Price DECIMAL(10,2),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    FOREIGN KEY (SeasonID) REFERENCES Seasons(SeasonID),
    CONSTRAINT CK_Price CHECK (Price > 0)
);

/* =========================================
   INVENTORY
   ========================================= */
CREATE TABLE Inventories (
    StoreID INT,
    ProductID INT,
    StockQuantity INT,
    PRIMARY KEY (StoreID, ProductID),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CK_Stock CHECK (StockQuantity >= 0)
);

/* =========================================
   CUSTOMER & SALES
   ========================================= */
CREATE TABLE Customers (
    CustomerID INT IDENTITY PRIMARY KEY,
    FullName NVARCHAR(100),
    Gender NVARCHAR(10),
    BirthDate DATE,
    Email NVARCHAR(150) UNIQUE,
    CONSTRAINT CK_Gender CHECK (Gender IN ('Male','Female','Other'))
);

CREATE TABLE Sales (
    SaleID INT IDENTITY PRIMARY KEY,
    StoreID INT,
    CustomerID INT,
    EmployeeID INT,
    SaleDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE SaleDetails (
    SaleDetailID INT IDENTITY PRIMARY KEY,
    SaleID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (SaleID) REFERENCES Sales(SaleID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Payments (
    PaymentID INT IDENTITY PRIMARY KEY,
    SaleID INT,
    Amount DECIMAL(10,2),
    PaymentMethod NVARCHAR(30),
    FOREIGN KEY (SaleID) REFERENCES Sales(SaleID),
    CONSTRAINT CK_Amount CHECK (Amount > 0)
);

/* =========================================
   TRIGGER – STOCK CONTROL
   ========================================= */
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
GO

/* =========================================
   STATIC DATA
   ========================================= */
INSERT INTO Categories VALUES
('Espresso'),('Brewed Coffee'),('Cold Brew'),('Tea'),
('Herbal Tea'),('Frappuccino'),('Cold Drinks'),
('Dessert'),('Bakery'),('Sandwich'),('Breakfast'),
('Vegan'),('Seasonal');

INSERT INTO Seasons VALUES
('Winter'),('Summer'),('Spring'),('Autumn'),('All');

INSERT INTO Countries VALUES ('Türkiye');

INSERT INTO Cities (CityName, CountryID)
VALUES
('İstanbul',1),('Ankara',1),('İzmir',1),
('Bursa',1),('Antalya',1),('Adana',1),
('Gaziantep',1);

INSERT INTO Districts (DistrictName, CityID)
SELECT d.DistrictName, c.CityID
FROM Cities c
JOIN (
    VALUES
    ('İstanbul','Kadıköy'),('İstanbul','Beşiktaş'),
    ('İstanbul','Üsküdar'),('Ankara','Çankaya'),
    ('Ankara','Keçiören'),('İzmir','Konak'),
    ('İzmir','Karşıyaka'),('Bursa','Nilüfer'),
    ('Antalya','Muratpaşa'),('Adana','Seyhan'),
    ('Gaziantep','Şahinbey')
) d(CityName, DistrictName)
ON c.CityName = d.CityName;

/* =========================================
   STORES & EMPLOYEES
   ========================================= */
INSERT INTO Stores
SELECT
    d.DistrictName + ' Store',
    d.DistrictID,
    DATEADD(DAY,-ABS(CHECKSUM(NEWID()))%3000,GETDATE()),
    CASE WHEN d.DistrictID % 2 = 0 THEN 'AVM' ELSE 'Cadde' END
FROM Districts d;

INSERT INTO Employees
SELECT
    s.StoreID,
    'Employee-' + CAST(s.StoreID AS NVARCHAR) + '-' + CAST(n AS NVARCHAR),
    CASE WHEN n=1 THEN 'Manager' ELSE 'Barista' END,
    CASE WHEN n=1 THEN 22000 ELSE 15000 END
FROM Stores s
CROSS JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) x;

/* =========================================
   PRODUCTS & INVENTORY
   ========================================= */
INSERT INTO Products
SELECT
    'Product-' + CAST(n AS NVARCHAR),
    ABS(CHECKSUM(NEWID())) % 13 + 1,
    ABS(CHECKSUM(NEWID())) % 5 + 1,
    20 + ABS(CHECKSUM(NEWID())) % 40
FROM (SELECT TOP 120 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) n FROM sys.objects) x;

INSERT INTO Inventories
SELECT s.StoreID, p.ProductID, 300 + ABS(CHECKSUM(NEWID())) % 700
FROM Stores s
CROSS JOIN Products p;

/* =========================================
   CUSTOMERS (20.000)
   ========================================= */
DECLARE @i INT = 1;
WHILE @i <= 20000
BEGIN
    INSERT INTO Customers
    VALUES (
        'Customer-' + CAST(@i AS NVARCHAR),
        CASE WHEN @i % 2 = 0 THEN 'Male' ELSE 'Female' END,
        DATEADD(YEAR,-(20+ABS(CHECKSUM(NEWID()))%40),GETDATE()),
        'customer'+CAST(@i AS NVARCHAR)+'@mail.com'
    );
    SET @i += 1;
END;

/* =========================================
   SALES (50.000)
   ========================================= */
DECLARE @s INT = 1;
DECLARE @maxStore INT = (SELECT MAX(StoreID) FROM Stores);
DECLARE @maxCust INT = (SELECT MAX(CustomerID) FROM Customers);
DECLARE @maxProd INT = (SELECT MAX(ProductID) FROM Products);

WHILE @s <= 50000
BEGIN
    DECLARE @store INT = 1 + ABS(CHECKSUM(NEWID())) % @maxStore;
    DECLARE @cust INT = 1 + ABS(CHECKSUM(NEWID())) % @maxCust;
    DECLARE @emp INT = (SELECT TOP 1 EmployeeID FROM Employees WHERE StoreID=@store);
    DECLARE @saleID INT;

    INSERT INTO Sales (StoreID,CustomerID,EmployeeID)
    VALUES (@store,@cust,@emp);

    SET @saleID = SCOPE_IDENTITY();

    DECLARE @prod INT = 1 + ABS(CHECKSUM(NEWID())) % @maxProd;

    INSERT INTO SaleDetails
    SELECT @saleID, ProductID, 1+ABS(CHECKSUM(NEWID()))%3, Price
    FROM Products WHERE ProductID=@prod;

    INSERT INTO Payments
    SELECT @saleID, SUM(Quantity*UnitPrice), 'Credit Card'
    FROM SaleDetails WHERE SaleID=@saleID;

    SET @s += 1;
END;
GO





-- Kış ayında çay tercih eden 20 yaş üstü erkek müşteriler

SELECT DISTINCT
    c.CustomerID,
    c.FullName,
    c.Gender,
    DATEDIFF(YEAR, c.BirthDate, GETDATE()) AS Age,
    c.Email,
    cat.CategoryName AS PreferredDrink
FROM Customers c
JOIN Sales s           ON s.CustomerID = c.CustomerID
JOIN SaleDetails sd    ON sd.SaleID = s.SaleID
JOIN Products p        ON p.ProductID = sd.ProductID
JOIN Categories cat    ON cat.CategoryID = p.CategoryID
JOIN Seasons se        ON se.SeasonID = p.SeasonID
WHERE
    c.Gender = 'Male'
    AND DATEDIFF(YEAR, c.BirthDate, GETDATE()) >= 20
    AND se.SeasonName = 'Winter'
    AND cat.CategoryName IN ('Tea','Herbal Tea');



 --Şehirlere göre toplam satış tutarı

SELECT
    ci.CityName,
    SUM(pay.Amount) AS TotalSalesAmount
FROM Payments pay
JOIN Sales s      ON s.SaleID = pay.SaleID
JOIN Stores st    ON st.StoreID = s.StoreID
JOIN Districts d  ON d.DistrictID = st.DistrictID
JOIN Cities ci    ON ci.CityID = d.CityID
GROUP BY ci.CityName
ORDER BY TotalSalesAmount DESC;



-- En çok satılan 5 ürün

SELECT TOP 5
    p.ProductName,
    SUM(sd.Quantity) AS TotalSold
FROM SaleDetails sd
JOIN Products p ON p.ProductID = sd.ProductID
GROUP BY p.ProductName
ORDER BY TotalSold DESC;



-- Mağaza bazında çalışan sayısı

SELECT
    st.StoreName,
    COUNT(e.EmployeeID) AS EmployeeCount
FROM Stores st
JOIN Employees e ON e.StoreID = st.StoreID
GROUP BY st.StoreName
ORDER BY EmployeeCount DESC;


--  Sezonlara göre satış adedi

SELECT
    se.SeasonName,
    COUNT(sd.SaleDetailID) AS TotalSales
FROM SaleDetails sd
JOIN Products p ON p.ProductID = sd.ProductID
JOIN Seasons se ON se.SeasonID = p.SeasonID
GROUP BY se.SeasonName
ORDER BY TotalSales DESC;


-- Ortalama sepet tutarı (sale başına)

SELECT
    AVG(pay.Amount) AS AverageBasketAmount
FROM Payments pay;



 --Stok seviyesi 100'ün altına düşen ürünler

SELECT
    st.StoreName,
    p.ProductName,
    i.StockQuantity
FROM Inventories i
JOIN Stores st   ON st.StoreID = i.StoreID
JOIN Products p  ON p.ProductID = i.ProductID
WHERE i.StockQuantity < 100
ORDER BY i.StockQuantity ASC;











