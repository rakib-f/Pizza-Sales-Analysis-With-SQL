/* SQL Project */

create database pizza_data_analysis;

use pizza_data_analysis

/* import the csv files as tables */

select * from order_details;
select * from orders;
select * from pizza_types;
select * from pizzas;

-- Basic:
-- Retrieve the total number of orders placed.

select count(distinct order_id) as Total_orders from orders; 

-- Calculate the total revenue generated from pizza sales.

select od.order_id, od.pizza_id, od.quantity, pz.pizza_id, pz.price
from order_details as od
join pizzas as pz
on od.pizza_id=pz.pizza_id;

select cast(sum(od.quantity * pz.price) as decimal(10,2)) as Total_revenue 
from order_details as od
join pizzas as pz
on od.pizza_id=pz.pizza_id;

-- Identify the highest-priced pizza.
-- highest in all pizzas

with cte as (
select pt.name as Pizza_name, pz.price as Price
from pizza_types as pt
join pizzas as pz
on pt.pizza_type_id=pz.pizza_type_id
)
select top 1 * from cte
order by 2 desc;

-- highest in each pizza category

with cte as (
select pizza_types.name as 'Pizza Name', cast(pizzas.price as decimal(10,2)) as Price,
rank() over (partition by pizza_types.name order by price desc) as rnk
from pizzas
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
)
select [Pizza Name], Price from cte where rnk = 1;

-- Identify the most common pizza size ordered.

select od.order_id, od.pizza_id, pz.pizza_id, od.quantity, pz.size
from order_details as od
join pizzas as pz
on od.pizza_id=pz.pizza_id;

select pz.size, count(distinct od.order_id) as 'No of orders', sum(od.quantity) as 'Total quantity ordered'
from order_details as od
join pizzas as pz
on od.pizza_id=pz.pizza_id
group by pz.size
order by 2 desc;

-- List the top 5 most ordered pizza types along with their quantities.

select top 5 pt.name as 'Pizza Name', count(distinct(od.order_id)) as 'Total Order', sum(od.quantity) as 'Total Quantity'
from order_details as od
join pizzas as pz
on od.pizza_id=pz.pizza_id
join pizza_types as pt
on pz.pizza_type_id=pt.pizza_type_id
group by pt.name
order by 2 desc;

-- Intermediate:
-- Join the necessary tables to find the total quantity of each pizza category ordered.

select pt.category as 'Pizza Category', sum(od.quantity) as 'Total Quantity'
from order_details as od
join pizzas as pz on od.pizza_id=pz.pizza_id
join pizza_types as pt on pz.pizza_type_id=pt.pizza_type_id
group by pt.category
order by 2 desc;

-- Determine the distribution of orders by hour of the day.

select left(time, 2) as 'Hour of the day', count(distinct order_id) as 'Total ordered'
from orders
group by left(time, 2) order by 2 desc;

-- Join relevant tables to find the category-wise distribution of pizzas.

select category as 'Pizza category', count(distinct pizza_type_id) as 'No of pizzas'
from pizza_types
group by category
order by 2 desc;

-- Group the orders by date and calculate the average number of pizzas ordered per day.

WITH cte AS (
    SELECT date AS [Date], SUM(quantity) AS [No of orders]
    FROM order_details as od
	join orders as o on od.order_id=o.order_id
    GROUP BY date
)
SELECT AVG([No of orders]) AS [Average number of pizzas ordered per day]
FROM cte;

-- Determine the top 3 most ordered pizza types based on revenue.

select top 3 pt.name as [Pizza name], cast(sum(quantity*price) as decimal(10,2)) as [Total Revenue]
from order_details as od
join pizzas as pz on od.pizza_id=pz.pizza_id
join pizza_types as pt on pz.pizza_type_id=pt.pizza_type_id
group by pt.name
order by 2 desc;

--Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.

select [Pizza category], cast(([Revenue]/[Total revenue])*100 as decimal(10,2)) as [Percentage contribution]
from
(
select *, sum([Revenue]) over() as [Total revenue]
from
(
select pt.category as [Pizza category], cast(sum(quantity*price) as decimal(10,2)) as [Revenue]
from order_details as od
join pizzas as pz on od.pizza_id=pz.pizza_id
join pizza_types as pt on pz.pizza_type_id=pt.pizza_type_id
group by pt.category
) as pizza_types
) as revenue;

-- Analyze the cumulative revenue generated over time.

-- converting the date column from varchar to date object

SELECT @@VERSION;

select distinct date from orders;

select date, try_convert(date, date, 101) from orders;

select date, try_cast(date as datetime2) from orders;

update orders
set date = try_convert(date, date, 101);

ALTER TABLE orders alter COLUMN date DATE;

-- rolling total

WITH cte AS
(
    SELECT o.date AS [Date], CAST(SUM(od.quantity * pz.price) AS DECIMAL(10, 2)) AS [Revenue]
    FROM orders AS o
    JOIN order_details AS od ON od.order_id = o.order_id 
    JOIN pizzas AS pz ON od.pizza_id = pz.pizza_id
    GROUP BY o.date
)
SELECT [Date], [Revenue], SUM([Revenue]) OVER (ORDER BY [Date]) AS [Rolling total]
FROM cte
ORDER BY [Date];

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with cte as
(
select pt.category as [Pizza category], pt.name as [Pizza name], cast(sum(quantity*price) as decimal(10,2)) as [Revenue]
from order_details as od
join pizzas as pz on od.pizza_id=pz.pizza_id
join pizza_types as pt on pz.pizza_type_id=pt.pizza_type_id
group by pt.category, pt.name
), ranking as
(
select *, dense_rank() over (partition by [Pizza category] order by [Revenue] desc) as ranks 
from cte
)
select [Pizza category], [Pizza name], [Revenue] from ranking where ranks < 4;