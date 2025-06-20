--1
WITH category_sales AS (
    SELECT
        p.category,
        SUM(oi.amount) AS total_sales,
        COUNT(DISTINCT o.id) AS total_orders
    FROM order_items oi
             JOIN orders o ON oi.order_id = o.id
             JOIN products p ON oi.product_id = p.id
    GROUP BY p.category
),
     total_overall AS (
         SELECT SUM(amount) AS grand_total
         FROM order_items
     )
SELECT
    category,
    total_sales,
    ROUND((total_sales / total_orders), 2) AS avg_per_order,
    ROUND((total_sales / (SELECT grand_total FROM total_overall)) * 100, 2) AS category_share
FROM category_sales
ORDER BY total_sales DESC;

--2
WITH order_totals AS (
    SELECT
        o.id AS order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.amount) AS order_total
    FROM orders o
             JOIN order_items oi ON o.id = oi.order_id
    GROUP BY o.id, o.customer_id, o.order_date
),
     customer_stats AS (
         SELECT
             customer_id,
             SUM(order_total) AS total_spent,
             ROUND(AVG(order_total), 2) AS avg_order_amount
         FROM order_totals
         GROUP BY customer_id
     )
SELECT
    ot.customer_id,
    ot.order_id,
    ot.order_date,
    ot.order_total,
    cs.total_spent,
    cs.avg_order_amount,
    ROUND(ot.order_total - cs.avg_order_amount, 2) AS difference_from_avg
FROM order_totals ot
         JOIN customer_stats cs ON ot.customer_id = cs.customer_id
ORDER BY ot.order_date, ot.order_id;

--3
WITH monthly_sales AS (
    SELECT
        TO_CHAR(order_date, 'YYYY-MM') AS year_month,
        SUM(oi.amount) AS total_sales
    FROM orders o
             JOIN order_items oi ON o.id = oi.order_id
    GROUP BY TO_CHAR(order_date, 'YYYY-MM')
    ORDER BY year_month
),
     sales_with_lag AS (
         SELECT
             year_month,
             total_sales,
             LAG(total_sales, 1) OVER (ORDER BY year_month) AS prev_month_sales,
             LAG(total_sales, 12) OVER (ORDER BY year_month) AS prev_year_sales
         FROM monthly_sales
     )
SELECT
    year_month,
    total_sales,
    ROUND(
            ((total_sales - prev_month_sales) / NULLIF(prev_month_sales, 0)) * 100,
            2
    ) AS prev_month_diff,
    ROUND(
            ((total_sales - prev_year_sales) / NULLIF(prev_year_sales, 0)) * 100,
            2
    ) AS prev_year_diff
FROM sales_with_lag
ORDER BY year_month;
