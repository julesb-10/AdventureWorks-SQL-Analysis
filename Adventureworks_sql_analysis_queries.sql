-- Analysis Queries:


-- 1. Top 10 Products by Total Profit

WITH total_rev_and_cost AS (SELECT p.model_name, SUM(s.order_quantity * p.product_price) AS total_revenue,
								   SUM(s.order_quantity * p.product_cost) AS cost_of_goods_sold
							FROM sales s
							LEFT JOIN products p -- LEFT JOIN as we want to keep all of the sales data in our results
							ON s.product_key = p.product_key
							GROUP BY p.model_name),
	 product_profits AS    (SELECT model_name, (total_revenue - cost_of_goods_sold) AS total_profit
							FROM total_rev_and_cost),
	 profit_rankings AS    (SELECT model_name, TO_CHAR(ROUND(total_profit, 2), 'FM999,999,999,990.00') AS total_profit,
								   RANK() OVER(ORDER BY total_profit DESC) AS profit_ranking
							FROM product_profits)							
SELECT *
FROM profit_rankings
WHERE profit_ranking <= 10;						

-- NOTE 1: some of these products come in different colors but have the same model_name so we
-- could initially group by product key if we wanted a more detailed view, and (LEFT) JOIN the end results
-- with the products table to see their names and colors

-- NOTE 2: Could have also used DENSE_RANK() depending on how we want the rankings to progress after a tie,
-- though it is very unlikely to have one when calculating values such as profit

-- NOTE 3: I used a LEFT JOIN for the sales and products table to keep all sales records. 
-- However, if it is known that there is a match for every product_key then it would be better 
-- to use an INNER JOIN as the query would become more efficient. in this case there is a match for
-- every product_key but I left the LEFT JOIN to generalize



-- Here's the query for the above NOTE 1 (taking colors into account and extending to top 20):
WITH total_rev_and_cost AS (SELECT s.product_key, SUM(s.order_quantity * p.product_price) AS total_revenue,
								   SUM(s.order_quantity * p.product_cost) AS cost_of_goods_sold
							FROM sales s
							LEFT JOIN products p -- LEFT JOIN as we want to keep all of the sales data in our results
							ON s.product_key = p.product_key
							GROUP BY s.product_key),
	 product_profits AS    (SELECT product_key, (total_revenue - cost_of_goods_sold) AS total_profit
							FROM total_rev_and_cost),
	 profit_rankings AS    (SELECT product_key, TO_CHAR(ROUND(total_profit, 2), 'FM999,999,999,990.00') AS total_profit,
								   RANK() OVER(ORDER BY total_profit DESC) AS profit_ranking
							FROM product_profits)							
SELECT p2.product_key, model_name, product_color, total_profit, profit_ranking
FROM profit_rankings pr
LEFT JOIN products p2
ON pr.product_key = p2.product_key
WHERE profit_ranking <= 20;

--COME BACK TO THIS (probably can delete)









-- 2. Return Rate by Product Subcategory

WITH total_subc_returns AS (SELECT ps.subcategory_name, SUM(return_quantity) AS total_returns
							FROM returns_data r
							LEFT JOIN products p
							ON r.product_key = p.product_key
							LEFT JOIN product_subcategories ps
							ON p.product_subcategory_key = ps.product_subcategory_key
							GROUP BY ps.subcategory_name),
	total_subc_orders AS   (SELECT ps.subcategory_name, SUM(order_quantity) AS total_ordered
							FROM sales s
							LEFT JOIN products p
							ON s.product_key = p.product_key
							LEFT JOIN product_subcategories ps
							ON p.product_subcategory_key = ps.product_subcategory_key
							GROUP BY ps.subcategory_name)
SELECT sr.subcategory_name, ROUND((total_returns * 1.0 / total_ordered) * 100, 3) || '%' AS return_rate
FROM total_subc_returns sr
INNER JOIN total_subc_orders so
ON sr.subcategory_name = so.subcategory_name
ORDER BY return_rate DESC;

-- NOTE 1: For the same reasoning as in the first question, LEFT JOINs are used to keep all return and sales data.
-- Could check beforehand to see if left joins lead to NULLs as in the following:

SELECT r.product_key
FROM returns_data r
LEFT JOIN products p
ON r.product_key = p.product_key
WHERE p.product_key IS NULL;

-- Returns an empty table meaning we have a corresponding match
-- for all product keys present in the returns table 

-- Can check going both ways:

SELECT r.product_key AS missing_key,
       'In returns_data but not in products' AS source
FROM returns_data r
LEFT JOIN products p
ON r.product_key = p.product_key
WHERE p.product_key IS NULL

UNION ALL

SELECT p.product_key AS missing_key,
       'In products but not in returns_data' AS source
FROM products p
LEFT JOIN returns_data r
ON p.product_key = r.product_key
WHERE r.product_key IS NULL;

-- Results appear but this is normal as not every product has been returned

-- Can check as well for product subcategory keys in products table and product subcategories table to be extra vigilant:
SELECT *
FROM products p
LEFT JOIN product_subcategories ps
ON p.product_subcategory_key = ps.product_subcategory_key
WHERE p.product_subcategory_key IS NULL;

--empty table again (after checking both ways) so we could use strictly INNER JOINs in our main query to speed up performance












-- 3. For each Country and Region, compute Total Sales, Number of (unique) customers and Average Order Quantity:

SELECT t.country,
	   t.region,
	   TO_CHAR(ROUND(SUM(s.order_quantity * p.product_price), 2), 'FM999,999,999,990.00') AS total_sales,
	   TO_CHAR(COUNT(DISTINCT s.customer_key), 'FM999,999,999,999') AS unique_customers, -- Taking from sales table in order to get number of ACTIVE unique customers who have bought at least one item
	   ROUND(AVG(order_quantity), 2) AS avg_order_quantity   
FROM sales s
LEFT JOIN territories t --LEFT JOIN to keep all sales data in case some territory keys don't have a match (though I have shown how to check)
ON s.territory_key = t.sales_territory_key
LEFT JOIN products p
ON s.product_key = p.product_key
GROUP BY t.country, t.region
ORDER BY total_sales DESC;


-- Using the information from the results of this query, we can go further and investigate KPIs such as
-- sales or revenue per customer and rank the regions by this metric to see which one 
-- is the most efficient on a customer level

-- Follow-up Query (previous query becomes a CTE):
WITH territory_metrics AS (SELECT t.country,
							      t.region,
							      ROUND(SUM(s.order_quantity * p.product_price), 2) AS total_sales,
							      COUNT(DISTINCT s.customer_key) AS unique_customers, -- In order to get number of ACTIVE unique customers who have bought at least one item
							      ROUND(AVG(order_quantity), 2) AS avg_order_quantity   
						   FROM sales s
						   LEFT JOIN territories t --LEFT JOIN to keep all sales data in case some territory keys don't have a match
						   ON s.territory_key = t.sales_territory_key
						   LEFT JOIN products p
						   ON s.product_key = p.product_key
						   GROUP BY t.country, t.region)
SELECT country,
	   region,
	   TO_CHAR(total_sales, 'FM999,999,999,990.00') AS country_region_sales,
	   TO_CHAR(unique_customers, 'FM999,999,999,999') AS unique_customers,
	   TO_CHAR(avg_order_quantity, 'FM999,999,999,999.00') AS avg_order_quantity,
	   TO_CHAR(ROUND((total_sales / unique_customers), 2), 'FM999,999,999,999.00') AS sales_per_customer -- Overall, not by transaction
FROM territory_metrics
ORDER BY total_sales DESC;


-- NOTE: We could very easily turn the 2nd query into a CTE and rank our countries and/or regions 
-- based off of a desired metric, the following query will do just this:

WITH territory_metrics AS (SELECT t.country,
							      t.region,
							      ROUND(SUM(s.order_quantity * p.product_price), 2) AS total_sales,
							      COUNT(DISTINCT s.customer_key) AS unique_customers,
							      ROUND(AVG(order_quantity), 2) AS avg_order_quantity   
						   FROM sales s
						   LEFT JOIN territories t
						   ON s.territory_key = t.sales_territory_key
						   LEFT JOIN products p
						   ON s.product_key = p.product_key
						   GROUP BY t.country, t.region),
	 metrics_2 		   AS (SELECT *,
							      ROUND((total_sales / unique_customers), 2) AS sales_per_customer 
						   FROM territory_metrics)						   
SELECT *,
	   RANK() OVER(ORDER BY total_sales DESC) AS sales_rank
FROM metrics_2;	   








-- 4. Monthly Sales Trends with Year-Over-Year Growth:

-- Our calendar table only has a date column. in our query we could just extract each date portion
-- but in the name of efficiency and readability, we'll bake them into the table:

-- Initializing new columns:
ALTER TABLE calendar
ADD COLUMN year INT,
ADD COLUMN month_name VARCHAR(15),
ADD COLUMN quarter INT;

-- Populating columns:
UPDATE calendar
SET
	year = EXTRACT(YEAR FROM date),
	month_name = TO_CHAR(date, 'Month'),
	quarter = EXTRACT(QUARTER FROM date);


-- Also will need month number:
ALTER TABLE calendar
ADD COLUMN month_num INT;

UPDATE calendar
SET month_num = EXTRACT(MONTH FROM date);



-- Now for our query:

WITH monthly_sales AS (SELECT c.year, c.month_num, c.month_name,
						      SUM(s.order_quantity * p.product_price) AS month_sales
					   FROM sales s
					   LEFT JOIN calendar c
					   ON s.order_date = c.date
					   LEFT JOIN products p
					   ON s.product_key = p.product_key
					   GROUP BY c.year, c.month_num, c.month_name)
SELECT ms1.year,
	   ms1.month_name, 
	   TO_CHAR(ms1.month_sales, 'FM999,999,999,990.00') AS month_sales,
	   prior.year AS prior_year,
	   TO_CHAR(prior.month_sales, 'FM999,999,999,990.00') AS prior_year_month_sales,
	   ROUND(((ms1.month_sales - prior.month_sales) / NULLIF(prior.month_sales, 0)) * 100, 2) || '%' AS yoy_pct_change -- NULLIF() to avoid division by 0
FROM monthly_sales ms1
INNER JOIN monthly_sales prior -- INNER JOIN since we're doing a self join and there won't be any mismatches
ON ms1.month_num = prior.month_num
AND ms1.year = prior.year + 1 -- + 1 on the prior year, or else logic is flawed
ORDER BY ms1.year DESC, ms1.month_num DESC;
-- ORDER BY in DESC fashion to see most recent months first in output




-- Alternate query that uses window functions instead (though maybe a bit less readable):

WITH monthly_sales AS (SELECT c.year, c.month_num, c.month_name,
						      SUM(s.order_quantity * p.product_price) AS month_sales
					   FROM sales s
					   LEFT JOIN calendar c
					   ON s.order_date = c.date
					   LEFT JOIN products p
					   ON s.product_key = p.product_key
					   GROUP BY c.year, c.month_num, c.month_name),
	sales_diff AS 	  (SELECT year,
						      month_num,
						      month_name,
						      month_sales,
						      LAG(month_sales) OVER(PARTITION BY month_num ORDER BY year) AS prior_year_month_sales,
							  ROUND(AVG(month_sales) OVER(ORDER BY year, month_num ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)) AS rolling_avg_6month_sales
					   FROM monthly_sales)
SELECT year,
	   month_num, 
	   month_name, 
	   TO_CHAR(month_sales, 'FM999,999,999,990.00') AS month_sales,
	   TO_CHAR(prior_year_month_sales, 'FM999,999,999,990.00') AS prior_year_month_sales,
	   TO_CHAR(rolling_avg_6month_sales, 'FM999,999,999,990.00') AS rolling_avg_6month_sales,
	   ROUND(((month_sales - prior_year_month_sales) / NULLIF(prior_year_month_sales, 0)) * 100, 2) || '%' AS yoy_sales_pct_change
FROM sales_diff
WHERE prior_year_month_sales IS NOT NULL -- Filtering out values where year is 2020 as there is nothing from 2019 in this dataset
ORDER BY year, month_num;

-- NOTE 1: could ORDER BY year and month_num DESC to see most recent months as in the first query

-- NOTE 2: We could also create a table with all possible dates and months in case some are missing
-- in our data, as the LAG() function depends on complete data 

--NOTE 3: Added in a 6-month rolling average for more insight, though it does clutter the output a tiny bit






-- 5. Customer Lifetime Value Segmentation (Top 10% as top-tier, Next 40% as mid-tier, bottom 50% as lower-tier)

-- Will start by adding a column to the customers table with their full_name
ALTER TABLE customers
ADD COLUMN full_name VARCHAR;

UPDATE customers
SET full_name = INITCAP(TRIM(first_name) || ' ' || TRIM(last_name)); --Adding TRIM in case the data needs it
-- NOTE: MYSQL equivalent of INITCAP() is PROPER()


-- The main query:
WITH cltv      AS    (SELECT c.full_name AS customer_name,
					         SUM(s.order_quantity * p.product_price) AS customer_lifetime_value
				      FROM sales s
				      LEFT JOIN products p
				      ON s.product_key = p.product_key
				      LEFT JOIN customers c
				      ON s.customer_key = c.customer_key
				      GROUP BY c.full_name),
	 ltv_rankings AS (SELECT customer_name,
						    ROUND(customer_lifetime_value, 2) AS customer_lifetime_value,
							NTILE(10) OVER(ORDER BY customer_lifetime_value DESC) AS customer_quantile,
						    DENSE_RANK() OVER(ORDER BY customer_lifetime_value DESC) AS ltv_ranking, -- Using DENSE_RANK() here because
							(SELECT SUM(customer_lifetime_value) FROM cltv) AS total_ltv
					 FROM cltv)			  
SELECT customer_name,
	   TO_CHAR(customer_lifetime_value, 'FM999,999,999,990.00') AS customer_lifetime_value,
	   ltv_ranking,
	   CASE 
	   		WHEN customer_quantile = 1 THEN 'Top Tier'
			WHEN customer_quantile BETWEEN 2 AND 5 THEN 'Mid-Tier'
			WHEN customer_quantile > 5 THEN 'Bottom-Tier'
			END AS customer_tier,
	   ROUND((customer_lifetime_value / total_ltv) * 100, 2) || '%' AS total_ltv_pct_contribution -- i.e % of sales
FROM ltv_rankings
ORDER BY customer_lifetime_value::NUMERIC DESC;
	   
-- NOTE 1: Casting customer ltv back to NUMERIC to order results by it.  
-- With very large volumes of data this could just make the query slower to run so
-- maybe it would be better to leave cltv as is, without formatting. Definitely
-- something to take into account however I'll leave it as is here

-- NOTE 2: the total_ltv_pct_contribution column in the output doesn't add too much
-- information here and may have been unnecessary, I just added it to show the logic behind doing 
-- it but in other contexts it could prove to show some very useful insight

-- Using the previous query as a subquery, we can easily find what % each tier contributes to the company's revenue,
--  We could also add another CTE to the previous query. Here I'll take the subquery approach to change things up,
-- though the CTE approach would be more readable

SELECT customer_tier, 
	   TO_CHAR(SUM(customer_lifetime_value), 'FM999,999,999,990.00') AS total_ltv,
	   ROUND(SUM(customer_lifetime_value) / (SELECT SUM(s.order_quantity * p.product_price) FROM sales s
	   										  INNER JOIN products p ON s.product_key = p.product_key) * 100, 2) || '%' AS pct_of_revenue,
	   TO_CHAR(COUNT(*), 'FM999,999,999,990.00') AS customers_in_tier,
	   TO_CHAR(ROUND(AVG(customer_lifetime_value), 2), 'FM999,999,999,990.00') AS ltv_per_customer
FROM 
	(WITH cltv      AS    (SELECT c.full_name AS customer_name,
						         SUM(s.order_quantity * p.product_price) AS customer_lifetime_value
					      FROM sales s
					      LEFT JOIN products p
					      ON s.product_key = p.product_key
					      LEFT JOIN customers c
					      ON s.customer_key = c.customer_key
					      GROUP BY c.full_name),
		 ltv_rankings AS (SELECT customer_name,
							    ROUND(customer_lifetime_value, 2) AS customer_lifetime_value,
								NTILE(10) OVER(ORDER BY customer_lifetime_value DESC) AS customer_quantile,
							    DENSE_RANK() OVER(ORDER BY customer_lifetime_value DESC) AS ltv_ranking, -- Using DENSE_RANK() here because
								(SELECT SUM(customer_lifetime_value) FROM cltv) AS total_ltv
						 FROM cltv)			  
	SELECT customer_name,
		   customer_lifetime_value,
		   ltv_ranking,
		   CASE 
		   		WHEN customer_quantile = 1 THEN 'Top Tier'
				WHEN customer_quantile BETWEEN 2 AND 5 THEN 'Mid-Tier'
				WHEN customer_quantile > 5 THEN 'Bottom-Tier'
				END AS customer_tier,
		   ROUND((customer_lifetime_value / total_ltv) * 100, 2) || '%' AS total_ltv_pct_contribution
	FROM ltv_rankings
	ORDER BY customer_lifetime_value DESC)
GROUP BY customer_tier
ORDER BY pct_of_revenue DESC;



-- 6. Top 5 Products with Longest Average Lead Time

-- MAIN QUERY
WITH lead_times      AS (SELECT p.model_name,
					 		    ROUND(AVG(order_date - stock_date), 2) AS avg_lead_time_days
					 	 FROM sales s
						 INNER JOIN products p
						 ON s.product_key = p.product_key
						 GROUP BY p.model_name),
	 lead_time_ranks AS (SELECT model_name,
							    avg_lead_time_days,
							    DENSE_RANK() OVER(ORDER BY avg_lead_time_days DESC) AS lead_time_rank
						 FROM lead_times)					
SELECT model_name,
	   avg_lead_time_days,
	   ROUND(avg_lead_time_days - (SELECT AVG(order_date - stock_date) FROM sales), 2) AS diff_from_avg_in_days,
	   lead_time_rank
FROM lead_time_ranks
WHERE lead_time_rank <= 5;	   

-- NOTE: If we wanted out average lead time calculation to be in months, 
-- we could use AGE() when calculating the difference between order_date and stock_date


-- NOTE: Used DENSE_RANK() but this can easily be changed based on preference.
-- Also, reversing the order by will give our top 5 fastest-selling products








-- 7. Contribution of Top Products to Total Revenue (Pareto Analysis)
-- In other words, seeing if top 20% of products contribute to ~80% of revenue

-- Starting with top 20% of products in terms of revenue:

WITH product_revenues AS (SELECT p.model_name,
							     SUM(s.order_quantity * p.product_price) AS revenue
						  FROM sales s
						  INNER JOIN products p
						  ON s.product_key = p.product_key
						  GROUP BY p.model_name),
	product_quantiles AS (SELECT model_name,
							     revenue,
							     NTILE(5) OVER(ORDER BY revenue DESC) AS pctile_group
						  FROM product_revenues),
	overall_revenue 	  AS (SELECT 
							     SUM(s.order_quantity * p.product_price) AS total_revenue
						  FROM sales s
						  INNER JOIN products p
						  ON s.product_key = p.product_key)
SELECT 
	   TO_CHAR(ROUND(SUM(revenue), 2), 'FM999,999,999,990.00') AS top_20_pct_revenue,
	   TO_CHAR(ROUND((SELECT total_revenue FROM overall_revenue), 2), 'FM999,999,999,990.00') AS total_revenue,
	   ROUND((SUM(revenue) / (SELECT total_revenue FROM overall_revenue)) * 100, 2) || '%' AS top_20_pct_contribution
FROM product_quantiles
WHERE pctile_group = 1;

-- Top 20% of products account for about 86.83% of revenue

-- NOTE 1: Included the overall_revenue CTE to make the subsequent subquery more readable

-- NOTE 2: Using inner joins now as I know this dataset has matches throughout every table,
-- stuck with LEFT JOINS previously to generalize


-- Bottom 80% of products therefore contribute (100 - 86.83) = 13.17%


-- 8. Sales Loss from Returns by Territory
SELECT t.country,
	   t.region,
	   ROUND(SUM(r.return_quantity * p.product_price), 2) AS return_losses
FROM returns_data r
INNER JOIN products p
ON r.product_key = p.product_key
INNER JOIN territories t
ON r.territory_key = t.sales_territory_key
GROUP BY t.country, t.region
ORDER BY return_losses DESC;

-- Within a company, further investigation could be done as to what is driving high return losses
-- in places such as Australia and the Southwest (United States)







-- 9. Impact of Customer Demographics on Spending

-- Looking at education level:
SELECT c.education_level,
	   TO_CHAR(ROUND(SUM(s.order_quantity * p.product_price), 2), 'FM999,999,999,990.00') AS amount_spent
FROM sales s
INNER JOIN products p
ON s.product_key = p.product_key
INNER JOIN customers c
ON s.customer_key = c.customer_key
GROUP BY c.education_level
ORDER BY amount_spent DESC;

-- Group with highest spending: Bachelors

-- Now for Occupation:
SELECT c.occupation,
	   TO_CHAR(ROUND(SUM(s.order_quantity * p.product_price), 2), 'FM999,999,999,990.00') AS amount_spent
FROM sales s
INNER JOIN products p
ON s.product_key = p.product_key
INNER JOIN customers c
ON s.customer_key = c.customer_key
GROUP BY c.occupation
ORDER BY amount_spent DESC;

-- Professionals stand out as the highest spenders for this company

-- Combining both Education and Occupation:

SELECT c.education_level,
	   c.occupation,
	   TO_CHAR(ROUND(SUM(s.order_quantity * p.product_price), 2), 'FM999,999,999,990.00') AS amount_spent,
	   ROUND(SUM(s.order_quantity * p.product_price) / (SELECT SUM(s1.order_quantity * p1.product_price)
														    FROM sales s1
														    INNER JOIN products p1
														    ON s1.product_key = p1.product_key) * 100, 2) || '%' AS pct_contribution_to_revenue
FROM sales s
INNER JOIN products p
ON s.product_key = p.product_key
INNER JOIN customers c
ON s.customer_key = c.customer_key
GROUP BY c.education_level, c.occupation
ORDER BY SUM(s.order_quantity * p.product_price) DESC; -- Just ordering by amount_spent to reveal highest-spending combinations of education and occupation




-- Could also look at different income brackets, how much they've spent, and how much they contribute to revenue:

WITH 	 income_groups 		 AS (SELECT customer_key,
									   NTILE(5) OVER(ORDER BY annual_income DESC) AS income_group
							 	 FROM customers),
	      sales_with_income  AS (SELECT (s.order_quantity * p.product_price) AS amount_spent,
		  								ig.income_group
								 FROM sales s
								 INNER JOIN income_groups ig
								 ON s.customer_key = ig.customer_key
								 INNER JOIN products p
								 ON s.product_key = p.product_key),
		 total_revenue 		 AS (SELECT SUM(s1.order_quantity * p1.product_price) AS total_rev
		 						 FROM sales s1
								 INNER JOIN products p1
								 ON s1.product_key = p1.product_key)
SELECT CASE income_group
			WHEN 1 THEN 'Top 20%'
			WHEN 2 THEN 'Upper-Middle 20%'
			WHEN 3 THEN 'Middle 20%'
			WHEN 4 THEN 'Lower-Middle 20%'
			WHEN 5 THEN 'Bottom 20%'
	   END AS income_group,
	   TO_CHAR(ROUND(SUM(amount_spent), 2), 'FM999,999,999,990.00') AS group_spend,
	   ROUND(SUM(amount_spent) / (SELECT total_rev FROM total_revenue) * 100, 2) || '%' AS pct_revenue_contribution
FROM sales_with_income
GROUP BY income_group
ORDER BY group_spend DESC;								 


--Additional Query to see what countries and regions have the most high income customers (in top 2 income groups)

WITH  income_groups AS (SELECT customer_key,
							   NTILE(5) OVER(ORDER BY annual_income DESC) AS income_group
						FROM customers)
SELECT t.country, 
	   t.region,
	   COUNT(DISTINCT s.customer_key) AS high_income_customers
FROM sales s
INNER JOIN territories t
ON s.territory_key = t.sales_territory_key
INNER JOIN income_groups ig
ON s.customer_key = ig.customer_key
WHERE income_group <= 2
GROUP BY t.country, t.region
ORDER BY high_income_customers DESC;







-- 10. Most Profitable Territories (Adjusted for Returns)

WITH territory_revenue AS (SELECT t.country,
							      t.region, 
							      SUM(s.order_quantity * p.product_price) AS total_revenue
						   FROM sales s
						   INNER JOIN territories t
						   ON s.territory_key = t.sales_territory_key
						   INNER JOIN products p
						   ON s.product_key = p.product_key
						   GROUP BY t.country, t.region),
  territory_sales_cost AS (SELECT t.country,
							      t.region, 
							      SUM(s.order_quantity * p.product_cost) AS total_cost
						   FROM sales s
						   INNER JOIN territories t
						   ON s.territory_key = t.sales_territory_key
						   INNER JOIN products p
						   ON s.product_key = p.product_key
						   GROUP BY t.country, t.region),
 territory_return_cost AS (SELECT t.country,
 								  t.region,
 								  SUM(r.return_quantity * p.product_cost) AS returns_cost
 						   FROM returns_data r
						   INNER JOIN products p
						   ON r.product_key = p.product_key
						   INNER JOIN territories t
						   ON r.territory_key = t.sales_territory_key
						   GROUP BY t.country, t.region)						   
SELECT tr.country, 
	   tr.region,
	   TO_CHAR(ROUND(COALESCE((total_revenue - total_cost - returns_cost), (total_revenue - total_cost)), 2), 'FM999,999,999,990.00') AS returns_adj_profit
FROM territory_revenue tr														
INNER JOIN territory_sales_cost tsc
ON (tr.country, tr.region) = (tsc.country, tsc.region)
LEFT JOIN territory_return_cost trc -- LEFT JOIN in case some territories have no returns
ON (tr.country, tr.region) = (trc.country, trc.region)
ORDER BY returns_adj_profit DESC;

-- NOTE: COALESCE used in case a territory has no returns, which would return a null value for returns_adj_profit





-- 11. Identifying Frequently Returned Products with Low Profit Margins (Candidates for Discontinuation)

-- Products with highest return rates:

WITH return_totals AS (SELECT p.model_name,
						      SUM(return_quantity) AS total_returned
					   FROM returns_data r
					   INNER JOIN products p
					   ON r.product_key = p.product_key
					   GROUP BY p.model_name),
	 order_totals  AS (SELECT p.model_name,
						      SUM(order_quantity) AS total_ordered
					   FROM sales s
					   INNER JOIN products p
					   ON s.product_key = p.product_key
					   GROUP BY p.model_name),
      return_rates AS (SELECT rt.model_name,
						      ROUND((total_returned * 1.0 / total_ordered) * 100, 2) AS return_rate
					   FROM return_totals rt
					   INNER JOIN order_totals ot
					   ON rt.model_name = ot.model_name
					   ORDER BY return_rate DESC),
   product_margins AS (SELECT model_name,
						      ROUND(AVG(product_price - product_cost), 2) AS profit_margin -- there can be multiple models (different colors, etc.)
					   FROM products
					   GROUP BY model_name),
  margin_quantiles AS (SELECT model_name,
						      profit_margin,
						      NTILE(5) OVER(ORDER BY profit_margin DESC) AS margin_quantile
					   FROM product_margins),
  return_quantiles AS (SELECT model_name,
						      return_rate,
						      NTILE(5) OVER(ORDER BY return_rate DESC) AS returns_quantile
					   FROM return_rates)	
SELECT mq.model_name, mq.profit_margin, rq.return_rate || '%' AS return_rate
FROM margin_quantiles mq
INNER JOIN return_quantiles rq
ON mq.model_name = rq.model_name
WHERE mq.margin_quantile >= 4 AND rq.returns_quantile = 1 -- i.e models in bottom 20% of margins and top 20% of return rates
ORDER BY profit_margin, return_rate::NUMERIC DESC;

-- Query may not be the most efficient 
-- Could look further into how much the products bring in and other factors to see 
-- if it would be detrimental to discontinue or not








-- 12. Per-Product Subcategory 3-Month Moving Average
WITH subcat_monthly_revenues AS (SELECT c.year,
									    c.month_num AS month,
									    ps.subcategory_name,
									    ROUND(SUM(s.order_quantity * p.product_price), 2) AS revenue_for_month
								 FROM sales s
								 INNER JOIN calendar c
								 ON s.order_date = c.date
								 INNER JOIN products p
								 ON s.product_key = p.product_key
								 INNER JOIN product_subcategories ps
								 ON p.product_subcategory_key = ps.product_subcategory_key
								 GROUP BY c.year, c.month_num, ps.subcategory_name)
SELECT year,
	   month,
	   subcategory_name,
	   TO_CHAR(revenue_for_month, 'FM999,999,999,990.00') AS revenue_for_month,
	   TO_CHAR(ROUND(AVG(revenue_for_month) OVER (PARTITION BY subcategory_name ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2), 'FM999,999,999,990.00') as moving_avg_3month
FROM subcat_monthly_revenues											
ORDER BY subcategory_name, year, month;

-- NOTE 1: In moving average window functon, i used RANGE instead of ROWS in case that there are non-consecutive months
-- i.e. if there are no sales for a subcategory uin a given month. This way the function still works

-- NOTE 2: Would be able to do forecasts in Power BI or Python using the 3-month average




-- 13. Cross-Category Purchase Analysis (Top 5 Most frequently purchased combination of subcategories)

WITH customer_subcat_purchases AS (SELECT DISTINCT c.customer_key,
									      ps.subcategory_name
								   FROM sales s
								   INNER JOIN products p
								   ON s.product_key = p.product_key
								   INNER JOIN product_subcategories ps
								   ON p.product_subcategory_key = ps.product_subcategory_key
								   INNER JOIN customers c
								   ON s.customer_key = c.customer_key), -- Maps each customer (key) to the subcategories of products they've bought
     multi_subcat_customers    AS (SELECT customer_key
								   FROM customer_subcat_purchases
								   GROUP BY customer_key
								   HAVING COUNT(subcategory_name) > 1), --Since we only want customers who have bought items from more than 1 subcategory								   
	 filtered_customers		   AS (SELECT csp.customer_key,
									      csp.subcategory_name
								   FROM customer_subcat_purchases csp
								   INNER JOIN multi_subcat_customers msc
								   ON csp.customer_key = msc.customer_key
								   ORDER BY csp.customer_key), -- Gives us a final list of customers who purchased from multiple subcategories along with the subcategories themselves	
								   -- CTE is technically not necessary but I chose to add it for readability purposes
	 subcat_pairs	   		   AS (SELECT fc1.subcategory_name AS subcategory_1,
									      fc2.subcategory_name AS subcategory_2
								   FROM filtered_customers fc1
								   INNER JOIN filtered_customers fc2 -- SELF JOIN to get pairs of subcategories purchased together for subsequent aggregation 
								   ON fc1.customer_key = fc2.customer_key
								   AND fc1.subcategory_name < fc2.subcategory_name) -- Avoids the same subcategories being listed next to each other in the output
SELECT subcategory_1, 
	   subcategory_2,
	   COUNT(*) AS pair_purchase_count,
	   ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_key) FROM multi_subcat_customers), 2) || '%' AS pct_of_multi_subcat_customers
	   -- Gives percentage of customers who purchased this subcategory pair out of those who purchased items from multiple subcategories
FROM subcat_pairs
GROUP BY subcategory_1, subcategory_2
ORDER BY pair_purchase_count DESC
LIMIT 5;

-- NOTE 1: The same could be done with products themselves (more granular) and with categories (more general) 

-- NOTE 2: As commented, the filtered_customers and subcat_pairs CTEs aren't really necessary and the code could be made more efficient
-- Here's a more efficient but less readable query:

WITH customer_subcat_purchases AS (SELECT DISTINCT c.customer_key,
									      ps.subcategory_name
								   FROM sales s
								   INNER JOIN products p
								   ON s.product_key = p.product_key
								   INNER JOIN product_subcategories ps
								   ON p.product_subcategory_key = ps.product_subcategory_key
								   INNER JOIN customers c
								   ON s.customer_key = c.customer_key), -- Maps each customer (key) to the subcategories of products they've bought
     multi_subcat_customers    AS (SELECT customer_key
								   FROM customer_subcat_purchases
								   GROUP BY customer_key
								   HAVING COUNT(subcategory_name) > 1) -- No need for DISTINCT here as it is already in the previous CTE, could still include it as a defensive mechanism
SELECT cs1.subcategory_name AS subcategory_1,
	   cs2.subcategory_name AS subcategory_2,
	   COUNT(*) AS pair_purchase_count,
	   ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_key) FROM multi_subcat_customers), 2) || '%' AS pct_of_multi_subcat_customers,
	   ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_key) FROM customers), 2) || '%' AS pct_of_all_customers
	   -- Percentage of ALL customers who have purchased these subcategory_pairs
FROM customer_subcat_purchases cs1
INNER JOIN customer_subcat_purchases cs2
ON cs1.customer_key = cs2.customer_key
AND cs1.subcategory_name < cs2.subcategory_name -- duplicate prevention
WHERE cs1.customer_key IN (SELECT customer_key FROM multi_subcat_customers)
GROUP BY subcategory_1, subcategory_2
ORDER BY pair_purchase_count DESC
LIMIT 10;
-- Produces same results but in a more efficient manner								 










