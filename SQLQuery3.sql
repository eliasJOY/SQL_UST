use WarehouseDB;
select* from warehouses;

--1 Find the Shape of the FMCG Table. 
select COUNT(*) as row_num from warehouses;
select COUNT(*) as col_num from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'warehouses';

--2 Evaluate the Impact of Warehouse Age on Performance. 
-- find the connection b/w age and and avg issues correalation
select (YEAR(GETDATE()) - wh_est_year) as Age,avg(storage_issue_reported_l3m) as Avg_Issues
from  warehouses
where wh_est_year is not null
group by (YEAR(GETDATE()) - wh_est_year)
order by Age desc;

--3 Analyze the Relationship Between Flood-Proof Status and Transport Issues. 
-- from the analysis it is inferred that non flood proof building cause more transport issues
select flood_proof,sum(transport_issue_l1y) as Tot_issues
from warehouses
group by flood_proof ;

--4 Evaluate the Impact of Government Certification on Warehouse Performance. 
-- data inconclusive for any inccursion
select distinct approved_wh_govt_certificate,sum(storage_issue_reported_l3m) as tot_issues,sum(wh_breakdown_l3m) as tot_breakdowns
from warehouses
group by approved_wh_govt_certificate ;

--5 Determine the Optimal Distance from Hub for Warehouses
-- Optimum dstance from hub is 162 with 0 transport issues.
select AVG(dist_from_hub) as avg_distance,transport_issue_l1y
from warehouses 
group by transport_issue_l1y
order by avg_distance;

--6 Identify the Zones with the Most Operational Challenges

select zone,sum(transport_issue_l1y)+
sum(storage_issue_reported_l3m) +sum(wh_breakdown_l3m) / 3 as AVG_issues
from warehouses
group by zone
order by AVG_issues desc;
-- North has the most operational challenges

--7 Examine the Effectiveness of Warehouse Distribution Strategy.
--Question: How effective is the current distribution strategy in each zone,
--based on the number of distributors connected to warehouses and their respective product weights?

select zone,avg(distributor_num),avg(product_wg_ton),sum(product_wg_ton)/ sum(distributor_num) as 
from warehouses
group by zone;
-- East has the best strategy and south and west has the worst one.

--8 Identify High-Risk Warehouses Based on Breakdown Incidents and Age. 
--Question: Which warehouses are at high risk of breakdowns, 
--especially considering their age and the number of breakdown 
--incidents reported in the last 3 months?

select Ware_house_ID,(YEAR(GETDATE()) - wh_est_year) AS age,wh_breakdown_l3m,
CASE
	when wh_breakdown_l3m > 3 then 'High Risk'
	when wh_breakdown_l3m > 1 then 'Medium Risk'
	else 'Low Risk'
END as risk_lvl
from warehouses
where (YEAR(GETDATE()) - wh_est_year) > 15 
order by wh_breakdown_l3m desc;

--7 Correlation Between Worker Numbers and Warehouse Issues. 
--Question: Is there a correlation between the number of workers in a warehouse 
--and the number of storage or breakdown issues reported?
select workers_num,sum(storage_issue_reported_l3m)+sum(wh_breakdown_l3m)/2 as avg_issues
from warehouses
group by workers_num
order by avg_issues desc;

--Inconclusive

--8 Assess the Zone-wise Distribution of Flood Impacted Warehouses.
--Question: Which zones are most affected by flood impacts, 
--and how does this affect their overall operational stability?

select zone, COUNT(*) as tot_warehouse,
SUM(case when flood_impacted = 1 then 1 else 0 )
from warehouses

-- 9 Calculate the Cumulative Sum of Total Working year for Each Zone. 
--Question: How can you calculate the cumulative sum of total working years for each zone?
select zone,sum(YEAR(GETDATE()) - wh_est_year) AS cumm_sum
from warehouses
group by zone;

SELECT 
    Zone,YEAR(GETDATE()) - wh_est_year AS working, SUM(YEAR(GETDATE()) - wh_est_year) OVER (PARTITION BY Zone ORDER BY wh_est_year) AS cumulative
FROM warehouses;

--10 Calculate the cummulative sum of total workers for each warehouse rating

SELECT approved_wh_govt_certificate,workers_num,
 SUM(workers_num) OVER (PARTITION BY approved_wh_govt_certificate 
 ORDER BY approved_wh_govt_certificate
 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS cumulative
FROM warehouses;

--11 Rank Warehouses Based on Distance from the Hub. 
--Question: How would you rank warehouses based on their distance from the hub?
select Ware_house_ID,dist_from_hub,
 dense_rank() over ( order by dist_from_hub) as ranks
from warehouses;

--12 Calculate the Running avg of Product Weight in Tons for Each Zone:
--Question: How can you calculate the running total of product weight in tons for each zone?


select zone,product_wg_ton,
 avg(product_wg_ton) over (partition by zone 
 order by  zone
 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS cumulative_avg
FROM warehouses;


--13 Rank Warehouses Based on Total Number of Breakdown Incidents. 
--Question: How can you rank warehouses based on the total number of breakdown
--incidents in the last 3 months?

select Ware_house_ID,wh_breakdown_l3m,
 dense_rank() over ( order by wh_breakdown_l3m) as ranks
from warehouses;

--14 Determine the Relation Between Transport Issues and Flood Impact.
--Question: Is there any significant relationship between the number of
--transport issues and flood impact status of warehouses?

select flood_impacted,sum(transport_issue_l1y) as Tot_issues
from warehouses
group by flood_impacted ;

-- Windows Functions

--15 Rank Warehouses by Product Weight within Each Zone:
--Question: How do you rank warehouses based on the product weight
--they handle within each zone, allowing ties?
select Ware_house_ID,zone,product_wg_ton,
 dense_rank() over ( partition by zone order by product_wg_ton  desc) as ranks
from warehouses;

--16 Determine the Most Efficient Warehouses Using DENSE_RANK. 
--Question: How can you use DENSE_RANK to find the most 
--efficient warehouses in terms of breakdown incidents within each zone?
select Ware_house_ID,zone,wh_breakdown_l3m,
 dense_rank() over ( partition by zone order by wh_breakdown_l3m  asc) as ranks
from warehouses;

--17 Calculate the Difference in Storage Issues Using LAG.
--Question: How can you use LAG to calculate the difference in storage 
--issues reported between consecutive warehouses within each zone?

with laggy as (select Ware_house_ID,zone,storage_issue_reported_l3m,
 lag(storage_issue_reported_l3m,1) over ( partition by zone order by Ware_house_ID asc) as lagg
from warehouses)
select Ware_house_ID,storage_issue_reported_l3m,zone, (storage_issue_reported_l3m - lagg )as Diff
from laggy;

--18 Compare Current and Next Warehouse's Distance Using LEAD:
--Question: How can you compare the distance from the hub of the current 
--warehouse to the next one using LEAD?
with laggy as (select Ware_house_ID,dist_from_hub,
 lead(dist_from_hub,1,0) over ( order by Ware_house_ID asc) as lagg
from warehouses)
select Ware_house_ID,dist_from_hub, (dist_from_hub-lagg )as Diff
from laggy ;

--19 Categorize Warehouses by Product Weight. 
--Question: How can you categorize warehouses as 'Low', 'Medium', or 'High'
--based on the amount of product weight they handle?
select MIN(product_wg_ton),MAX(product_wg_ton),AVG(product_wg_ton)
from warehouses;

select Ware_house_ID,zone,product_wg_ton,
case
	when product_wg_ton >=35000 then 'High'
	when product_wg_ton >=18000 then 'Medium'
	else 'Low'
end as Category
from warehouses
order by Category;
--methode 2 : using tile

select Ware_house_ID,product_wg_ton,
case
	when tile=3 then 'High'
	when tile=2 then 'Medium'
	else 'Low'
end as Category
from 
(select Ware_house_ID,product_wg_ton,
ntile(3) over (order by product_wg_ton) as tile from warehouses) as Tile
order by Category;

--20  Determine Risk Levels Based on Storage Issues.
--Question: How can you determine the risk level of each warehouse 
--based on the number of storage issues reported in the last 3 months?    DONE ALREADY!!


--21 Create a Stored Procedure to Fetch High-Risk Warehouses:
--Question: How would you create a stored procedure that returns all warehouses
--classified as 'High Risk' based on the number of breakdowns and storage issues?

create procedure HighRisk
as
begin

select* from(select Ware_house_ID,transport_issue_l1y,storage_issue_reported_l3m,wh_breakdown_l3m,
CASE
	when wh_breakdown_l3m > 5 and storage_issue_reported_l3m >10 and transport_issue_l1y >0 then 'High Risk'
END as risk from warehouses) as Risk_ 
where risk = 'High Risk';

end;
-- Executing the procedure
exec HighRisk;

--22 Create a Stored Procedure to Calculate Warehouse Efficiency:
--Question: How would you create a stored procedure to calculate and return 
--the efficiency of each warehouse based on its product weight and number of distributors?

create procedure Eff
as
begin

SELECT*
FROM (
    SELECT   Ware_house_ID,product_wg_ton, distributor_num, (product_wg_ton / distributor_num)
	AS Efficiency,
        CASE
            WHEN (product_wg_ton / distributor_num) > 2000 THEN 'Efficient'
            ELSE 'Not Efficient'
        END AS Eff FROM warehouses
) AS EffAssessmen

ORDER BY Efficiency DESC;

end;
exec Eff;

-- 23 Create a View for Warehouse Overview:
--Question: How can you create a view that shows an overview of warehouses,
--including their location, product weight, and flood-proof status?

create view Ware_View as
select Ware_house_ID,Location_type,product_wg_ton,flood_proof
from warehouses;

-- View creates a temporary table for useage that isnt stored. It can be used in queries but not stored.
--24 Create a view for high capacity warehouses. create  a view with ware houss > 100 ton

create view HighCap as 
select* from warehouses
where product_wg_ton >100;

select* from HighCap;