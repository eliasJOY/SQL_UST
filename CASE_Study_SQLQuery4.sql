declare @variable varchar(123)= 'TaxiDB';
if not exists(select 1 from sys.databases where name = @variable)
begin
	declare @SQL nvarchar(max) = 'create database' + quotename(@variable)
	exec sp_executesql @SQL
end

use TaxiDB;


CREATE TABLE [dbo].taxi_data (

    VendorID INT,
    lpep_pickup_datetime DATETIME, -- Make sure this matches the format in your data
    lpep_dropoff_datetime DATETIME, -- Make sure this matches the format in your data
    store_and_fwd_flag CHAR(6), -- Assuming 'N' or 'Y'
    RatecodeID INT,
    PULocationID INT,
    DOLocationID INT,
    passenger_count INT,
    trip_distance DECIMAL(10, 2), -- Increased precision for distance
    fare_amount DECIMAL(17, 2), -- Increased precision for fare amount
    extra DECIMAL(17, 2), -- Increased precision for extra charges
    mta_tax DECIMAL(15, 2), -- Precision for MTA tax
    tip_amount DECIMAL(17, 2), -- Increased precision for tip amount
    tolls_amount DECIMAL(17, 2), -- Increased precision for tolls amount
    ehail_fee DECIMAL(17, 2) NULL, -- Allow NULLs
    improvement_surcharge DECIMAL(15, 2), -- Precision for improvement surcharge
    total_amount DECIMAL(18, 2), -- Increased precision for total amount
    payment_type INT,
    trip_type INT,
    congestion_surcharge DECIMAL(5, 2) -- Precision for congestion surcharge
);

BULK INSERT taxi_data
FROM 'C:/Users/Administrator/Downloads/Green_Taxi_Data.csv'
WITH (
    FIELDTERMINATOR = ',',		-- '|' , ';' , '\t'  , ' '
    ROWTERMINATOR = '0x0a',     --Carriage and new line charecter - '\r\n' , '\n' , '' , '0x0a' (line feed)
    FIRSTROW = 2				--Skips the header from records    
);

select* from taxi_data;

--1. Shape of the Table (Number of Rows and Columns)
select count(*) from taxi_data;
select COUNT(*) from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'taxi_data';

--2. Show Summary of Green Taxi Rides – Total Rides, Total Customers, Total Sales, 
select COUNT(*) as Tot_Rides, SUM(passenger_count) as Tot_Customer,SUM(total_amount) as Tot_sales
from taxi_data
where total_amount>0 and passenger_count >0;


--3. Total Rides with Surcharge and its percentage. 
select trip_distance,(improvement_surcharge + congestion_surcharge) as Tot_surcharge,
((improvement_surcharge+congestion_surcharge)/total_amount *100) as surcharge_percent
from taxi_data
where total_amount >0 and improvement_surcharge > 0;

--11.Find Top 20 Most Frequent Rides Routes. 
select top(1) PULocationID,DOLocationID, COUNT(*) as route_count
from taxi_data
group by PULocationID,DOLocationID
order by route_count desc;


--12.Calculate the Average Fare of Completed Trips vs. Cancelled Trips
select AVG(fare_amount) as avg_comp_fare
from taxi_data
where trip_distance>0 and fare_amount is not null;
select AVG(fare_amount) as avg_cancelled_fare
from taxi_data
where trip_distance = 0 and fare_amount is not null;

--13.Rank the Pickup Locations by Average Trip Distance and Average Total Amount.
select PULocationID,AVG(trip_distance) as avg_dist,AVG(total_amount) as avg_amt,
 dense_rank() over ( order by avg(trip_distance) desc,avg(total_amount)desc ) as ranks
from taxi_data
group by PULocationID;



--14. Find the Relationship Between Trip Distance & Fare Amount

select avg(trip_distance),avg(fare_amount)
from taxi_data
where fare_amount>0 and trip_distance>0
order by trip_distance;


-- 15. Identify Trips with Outlier Fare Amounts within Each Pickup Location
select PULocationID, max(total_amount) as total_amount
from taxi_data group by PULocationID order by total_amount desc;

--16. Categorize Trips Based on Distance Travelled
select min(trip_distance),AVG(trip_distance),max(trip_distance)
from taxi_data ;

select trip_distance,
case
	when trip_distance >=5000 then 'Long Trip'
	else 'Short Trip'
end as Category
from taxi_data
where total_amount >0
order by Category;

-- 17. Top 5 Busiest Pickup Locations, Drop Locations with Fare less than median total fare
with medianfare as (select PERCENTILE_CONT(0.5) within group (order by total_amount) over() 
as MedianPrice
from taxi_data)
select top(5) PULocationID, DOLocationID, total_amount 
from taxi_data where total_amount<(select max(MedianPrice) from medianfare) and total_amount>0 
order by total_amount desc;


--18. Distribution of Payment Types
select payment_type,COUNT(payment_type) as Pay_count
from taxi_data
group by payment_type
order by payment_type;

-- 19. Trips with Congestion Surcharge Applied and Its Percentage Count.
select PULocationID, congestion_surcharge,
case
	when total_amount>0 then (congestion_surcharge * 100.0 / total_amount)
	else 0
end as perc
from taxi_data where congestion_surcharge>0;


--20. Top 10 Longest Trip by Distance and Its summary about total amount.
select top(10)* 
from taxi_data
order by trip_distance desc;


--21. Trips with a Tip Greater than 20% of the Fare
select trip_distance,(tip_amount/fare_amount)*100 as percentage_
from taxi_data
where (tip_amount/fare_amount >.2) 
and fare_amount>0
order by (tip_amount/fare_amount)  desc

-- 22. Average Trip Duration by Rate Code
select RatecodeID, avg(datediff(MINUTE,lpep_pickup_datetime,lpep_dropoff_datetime))as
avg_diff from taxi_data group by RatecodeID order by RatecodeID;


-- 23. Total Trips per Hour of the Day
select DATEPART(HOUR,lpep_pickup_datetime ) as day_hour,count(*) as tot_trips 
from taxi_data 
group by DATEPART(HOUR,lpep_pickup_datetime )
order by day_hour;

-- 24. Show the Distribution about Busiest Time in a Day.
select datepart(hour,lpep_pickup_datetime) as hour_,count(*) as trip_count
from taxi_data 
group by datepart(hour,lpep_pickup_datetime) 
order by trip_count desc;


