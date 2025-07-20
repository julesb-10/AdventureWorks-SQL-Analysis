# AdventureWorks Advanced SQL Analysis

This project explores the **AdventureWorks dataset** using advanced SQL techniques to extract actionable business insights.  
The analysis is focused on **sales, returns, customer demographics, and product performance**, and highlights how SQL can be used to answer real-world business questions.

---

## **Project Files**
- **AdventureWorks_sql_project_queries.sql**  
  Contains all **13 advanced SQL queries** answering key business questions. The queries demonstrate:
  - CTEs (Common Table Expressions)
  - Window functions (RANK, NTILE, LAG, etc.)
  - Aggregations and KPI calculations
  - Joins and subqueries
  - Analytical calculations (Pareto principle, moving averages, customer lifetime value, etc.)

- **AdventureWorks Analysis Write-up.pdf**  
  - Each **business question** answered.
  - **Screenshots of SQL query outputs** (top results summarized).
  - **Business insights and commentary** for each query.

- **README.md** 
  Provides an overview of the project, structure, and insights.

---

## **Key Topics and Questions Answered**
The analysis covers **13 advanced business questions**, including:

1. **Top 10 Products by Total Profit** – Identifies the most profitable products.
2. **Return Rate by Product Subcategory** – Analyzes return trends by subcategory.
3. **Country and Region Sales KPIs** – Total sales, unique customers, and average order quantity by region.
4. **Monthly Sales Trends (YOY Growth)** – Year-over-year sales comparison with a 6-month rolling average.
5. **Customer Lifetime Value Segmentation** – Tiering customers (top, mid, bottom) by lifetime value.
6. **Products with the Longest Lead Times** – Detects bottlenecks in order fulfillment.
7. **Pareto Analysis (Top Products Contribution)** – Verifies if 20% of products drive ~80% of revenue.
8. **Sales Losses from Returns by Territory** – Revenue impact of returns by region.
9. **Customer Demographics and Spending** – Spending trends by education, occupation, and income groups.
10. **Most Profitable Territories (Adjusted for Returns)** – Profit after factoring in product costs and returns.
11. **High Return & Low Profit Products** – Identifies potential candidates for discontinuation.
12. **3-Month Moving Average by Subcategory** – Detects sales trends using rolling averages.
13. **Cross-Category Purchase Analysis** – Finds the most common subcategory combinations bought by customers.

---

## **Skills and Tools Used**
- **Database:** PostgreSQL
- **SQL Techniques:** 
  - CTEs, window functions (RANK, DENSE_RANK, NTILE, LAG)
  - Aggregate and analytical functions
  - Subqueries and CASE statements
  - JOINS of all kinds
  - Date and time operations
- **Data Analysis Topics:**
  - Profitability and return analysis
  - Customer segmentation (CLTV, demographics, income brackets)
  - Rolling averages and time-based KPIs
  - Pareto principle validation
- **Documentation:** Google Docs (PDF version included)


---

## **Potential Next Steps**
- Implement **query optimizations** (indexing, EXPLAIN ANALYZE).
- Extend forecasting (from moving averages) using BI tools or Python.
- Create visual dashboards using Power BI or Tableau based on these SQL outputs.

---

**Author:** Jules Bellosguardo  
**LinkedIn:** *[https://www.linkedin.com/in/jules-bellosguardo-937117208/]*  
