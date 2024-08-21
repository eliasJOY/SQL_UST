declare @variable varchar(123)= 'WarehouseDB';
if not exists(select 1 from sys.databases where name = @variable)
begin
	declare @SQL nvarchar(max) = 'create database' + quotename(@variable)
	exec sp_executesql @SQL
end

use WarehouseDB;

CREATE TABLE [dbo].warehouses (
    Ware_house_ID VARCHAR(20) PRIMARY KEY,
    WH_Manager_ID VARCHAR(20),
    Location_type VARCHAR(10),
    WH_capacity_size VARCHAR(10),
    zone VARCHAR(10),
    WH_regional_zone VARCHAR(20),
    num_refill_req_l3m INT,
    transport_issue_l1y INT,
    Competitor_in_mkt INT,
    retail_shop_num INT,
    wh_owner_type VARCHAR(15),
    distributor_num INT,
    flood_impacted BIT,
    flood_proof BIT,
    electric_supply BIT,
    dist_from_hub INT,
    workers_num INT,
    wh_est_year INT,
    storage_issue_reported_l3m INT,
    temp_reg_mach INT,
    approved_wh_govt_certificate CHAR(5),
    wh_breakdown_l3m INT,
    govt_check_l3m INT,
    product_wg_ton INT
);

--drop table [dbo].warehouses;
bulk insert warehouses
from 'C:/Users/Administrator/Downloads/FMCG_data.csv'
with 
(
	fieldterminator = ',',
	rowterminator = '\n',
	firstrow = 2   --skips header for 2 lines 
)
select* from warehouses;
--1. Show number of records

select count(*) as num_records from warehouses;

--2. Query to find wharehouse with max and min capacity

select top(5) Ware_house_ID,product_wg_ton 
from warehouses
order by product_wg_ton desc;

select top(5) Ware_house_ID,product_wg_ton 
from warehouses
order by product_wg_ton ;

--3  tot no. of counts of zonal regions

select WH_regional_zone,count(*) 
from warehouses
group by  WH_regional_zone 
order by WH_regional_zone  ;

--5 find avg,min, max, median distance from hub warehouse with min capacity 10000 loc type = urban

with valuess as(
select dist_from_hub,PERCENTILE_CONT(0.5) within group (order by dist_from_hub) over() as median 
from warehouses
where product_wg_ton >10000 and Location_type = 'Urban')

select avg( dist_from_hub) as Avg_,min( dist_from_hub) as Min_, max (median) as Median ,max(dist_from_hub) as Max_
from valuess;

--6 Window Funtions : Performs calculations accross as set of table rows . Unlike aggregate functions
-- it can return more than one result .
-- windows functions can return top for each categories

select* from warehouses;

select Ware_house_ID, Location_type, zone, wh_owner_type, product_wg_ton, Competitor_in_mkt,
rank()  ( partition by Competitor_in_mkt order by product_wg_ton desc)
as W_rank from warehouses;

-- Same values for same category gives out same rank : 1,2,2,4,5,5,7
--hence we use dense_rank() : 1,2,2,3,4,4,5

-- Show top5 whithine RANK
with W_ranker as( 
select Ware_house_ID, Location_type, zone, wh_owner_type,approved_wh_govt_certificate,workers_num,
dense_rank() over ( partition by approved_wh_govt_certificate order by workers_num desc)
as W_rank from warehouses
)
select Ware_house_ID, Location_type, zone, wh_owner_type,approved_wh_govt_certificate,workers_num,W_rank
from W_ranker 
where W_rank <= 5;

-- Using sub query , top 5

select top(5)*
from (select Ware_house_ID, Location_type, zone, wh_owner_type,approved_wh_govt_certificate,workers_num,
dense_rank() over ( partition by approved_wh_govt_certificate order by workers_num desc)
as W_rank from warehouses) as ranker
where ranker.W_rank <=5;

--Lag & Lead : useful to show difference with row values
-- 
select Ware_house_ID, Location_type, zone, wh_owner_type,approved_wh_govt_certificate,product_wg_ton,
LEAD(product_wg_ton,1) over ( partition by approved_wh_govt_certificate order by workers_num desc)
as NEXT from warehouses;


-- NTILE
select Ware_house_ID, Location_type, zone, wh_owner_type,approved_wh_govt_certificate,product_wg_ton,
NTILE(1000) over ( partition by approved_wh_govt_certificate order by workers_num desc)
as Quartiels from warehouses; -- split into 5 equal parts and diplay the quartile

--Percent_rank()
select Ware_house_ID, Location_type, zone, wh_owner_type,approved_wh_govt_certificate,product_wg_ton,
PERCENT_RANK() over ( partition by approved_wh_govt_certificate order by workers_num desc)
as Percentile from warehouses;  -- Shows percentile ofeach from 0 to 1

--Show all records where no. of workers comes in range (0-40) percentile
select* from 
(select Ware_house_ID, Location_type, zone, wh_owner_type,approved_wh_govt_certificate,product_wg_ton,
PERCENT_RANK() over ( partition by approved_wh_govt_certificate order by workers_num desc)
as Percentile from warehouses) as percent_
where Percentile  <=.4;

-- find the difference between current and previous lag(2) values and rank it according to diff

with lagy as (select Ware_house_ID, WH_regional_zone,product_wg_ton,
LAG(product_wg_ton,2) over (order by product_wg_ton desc)
as prev from warehouses)
select Ware_house_ID,(prev - product_wg_ton ) as diff,
dense_rank() over (  order by (prev - product_wg_ton) desc)
as rank
from lagy;


