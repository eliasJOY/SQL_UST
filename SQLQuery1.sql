--T_SQL or Transact SQL which is extention of SQL
--T SQL developed by Microsoft for SQL server, Azure DQL DB
---Key Features: (1)Can create variables (2)Control flow of statement(IF-ELSE)
--LOOPS, TRY CATCH, CREATE FUNCTIONS, Stored procedures

--1. Show databases
SELECT name FROM sys.databases;
--2. Show list of schemas
SELECT name as SchemaName from sys.schemas;
--3. Create
--create database Sales;  

--4. Declaring a variable : check if it already exists
declare @variable varchar(123)= 'Sales1';
if not exists(select 1 from sys.databases where name = @variable)
begin
	declare @SQL nvarchar(max) = 'create database' + quotename(@variable)
	exec sp_executesql @SQL
end

use SALES;
create table [dbo].products(productid varchar(20) not null,
							productname varchar(50),
							price float, qty int,
							storename varchar(50),
							city varchar(20));
-- 8 insert data 
INSERT INTO [dbo].products (productid, productname, price, qty, storename, city)
VALUES 
('P001', 'Basmati Rice', 50.75, 100, 'Spice Store', 'Delhi'),
('P002', 'Chai Tea', 30.00, 200, 'Tea Time', 'Mumbai'),
('P003', 'Sari', 1500.00, 50, 'Fashion Hub', 'Kolkata'),
('P004', 'Ghee', 200.00, 75, 'Pure Foods', 'Bengaluru'),
('P005', 'Ayurvedic Oil', 250.00, 60, 'Herbal Store', 'Chennai');

-- view tables inside products
select* from products;

--9 SHows table info : description
select TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME,DATA_TYPE, IS_NULLABLE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'products';

--10 drop table
drop table [dbo].products;

-- 11 alter table
alter table products
add tot_bill float;

-- 12 update table
update products
set  tot_bill = price * qty;

--11 drop columns : alter
alter table products
add code varchar(20);

alter table products
drop column code;

--12 update schema

alter table products
alter column tot_bill decimal(18,2);
-- 13 first 5 records

select top(5)*
from  [dbo].products;



