#Task 1: Provide the list of markets in which customer "AtliQ Exclusive" operates its business in the APAC region.

select 
 distinct market
from dim_customer
where customer = "AtliQ exclusive" 
and region = "APAC";
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 2: What is the percentage of unique product increase in 2021 vs. 2020? 
#The final output contains these fields, unique_products_2020, unique_products_2021, percentage_chg .

with cte1 as (
	select count(distinct product_code) as unique_product_2020
	from fact_sales_monthly
	where fiscal_year = 2020
), 
cte2 as (
	select count(distinct product_code) as unique_product_2021
	from fact_sales_monthly
	where fiscal_year = 2021 
)
select 
	c1.unique_product_2020,
	c2.unique_product_2021,
	(c2.unique_product_2021-c1.unique_product_2020)*100/c1.unique_product_2020 as pct_change
	from cte1 c1
	join cte2 c2;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 3: Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
# The final output contains 2 fields, segment, product_count.

Select segment , count( distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 4: Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
# The final output contains these fields, segment product_count_2020 product_count_2021 difference

with unique_products as (
select
	p.segment, 
	count(distinct(case when fiscal_year = 2020 then s.product_code end)) as product_count_2020,
	count(distinct(case when fiscal_year = 2021 then s.Product_code end)) as product_count_2021
from fact_sales_monthly s
join dim_product p
	on s.product_code = p.product_code
group by p.segment )
select 
	*,
	product_count_2021-product_count_2020 as difference
from unique_products
order by difference desc ;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 5: Get the products that have the highest and lowest manufacturing costs. 
# The final output should contain these fields, product_code product manufacturing_cost

SELECT
    m.product_code,
    p.product,
    m.manufacturing_cost
FROM dim_product p
join fact_manufacturing_cost m
using(product_code)
WHERE
    manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
    or manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
order by manufacturing_cost desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 6: Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 
# and in the Indian market. The final output contains these fields, customer_code, customer, average_discount_percentage .

Select 
	pre.customer_code, c.customer,  
	round( AVG (pre_invoice_discount_pct) * 100, 2) as Avg_Discount_Pct
 from fact_pre_invoice_deductions pre
 join dim_customer c
	using(customer_code)
 where pre.fiscal_year="2021" and c.market="INDIA"
 group by pre.customer_code,c.customer
 order by Avg_discount_pct desc
 limit 5;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 7: Get the complete report of the Gross sales amount for the customer “AtliQ Exclusive” for each month. This analysis helps to get an idea of 
# low and high-performing months and take strategic decisions. The final report contains these columns: Month, Year, Gross sales Amount.

Select
	monthname(s.date) as Month ,
	s.fiscal_year as Year,
	sum(sold_quantity * gross_price) as Gross_sales
from fact_sales_monthly s
join fact_gross_price g
	using(product_code, fiscal_year)
join dim_customer c
	using(customer_code)
where customer = "AtliQ Exclusive"
group by month, year
order by year asc ;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 8: In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields 
# sorted by the total_sold_quantity, Quarter, total_sold_quantity.

select (
	case    
		when month(date)  in (9, 10, 11) then "Q1"  
		when month(date) in ( 12,1, 2) then "Q2" 
		when month(date) in ( 3, 4, 5) then "Q3"     
		when month (date) in (6,7,8) then "Q4" 
	end) as Quarter,
	Concat(Round(sum(sold_quantity)/1000000,2),'M') as total_sold_qty 
from fact_sales_monthly 
where fiscal_year = 2020 
group by Quarter
order by total_sold_qty desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 9: Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
# The final output contains these fields, channel, gross_sales_mln, percentage.

with cte1 as (
select
   c.channel,
   round(sum((s.sold_quantity*g.gross_price)/1000000),2) as gross_sales_mln
from fact_gross_price g 
join fact_sales_monthly s
    USING (product_code,fiscal_year)
join dim_customer c 
    USING (customer_code)
where s.fiscal_year = 2021
group by c.channel 
) 
select 
	*,
	concat(round(gross_sales_mln*100/(select sum(gross_sales_mln) from cte1),2)," %") as pct_contribution
from cte1
order by pct_contribution desc ;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Task 10: Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
# The final output contains these fields, division product_code product total_sold_quantity rank_order.

with cte1 as(
select 
	p.division,
	s.product_code,
	concat(p.product," (", p.variant,")") as product, 
	sum(s.sold_quantity) as total_sold_qty,
	rank() over(partition by p.division order by sum(s.sold_quantity) desc) as  rank_order
from dim_product p
join fact_sales_monthly s 
 using(product_code)
where fiscal_year = 2021
group by p.division,s.product_code,p.product 
)
select 
	*
from cte1
where rank_order in (1,2,3)
order by division, rank_order asc ;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------





