--1. Dataset
WITH rg
     AS (SELECT month,
                product_category,
                tpv,
                LAG(tpv) OVER (PARTITION BY product_category ORDER BY month) AS previous_month_revenue,
                CASE WHEN LAG(tpv) OVER (PARTITION BY product_category ORDER BY month) IS NOT NULL 
                     THEN CONCAT(ROUND((tpv - LAG(tpv) OVER (PARTITION BY product_category ORDER BY month) ) /
                          LAG(tpv) OVER (PARTITION BY product_category ORDER BY month), 3) * 100.0, '%')
                  ELSE NULL
                END AS revenue_growth
         FROM   (SELECT Format_date('%Y-%m', orders.created_at)      AS MONTH,
                        products.category                            AS Product_category,
                        CAST(Sum(order_items.sale_price) AS FLOAT64) AS TPV
                 FROM   bigquery-public-data.thelook_ecommerce.orders AS orders
                        JOIN bigquery-public-data.thelook_ecommerce.order_items AS order_items
                          ON orders.user_id = order_items.user_id
                        JOIN bigquery-public-data.thelook_ecommerce.products AS products
                          ON order_items.product_id = products.id
                 GROUP  BY 1, 2
                 ORDER  BY 1, 2) a
         ORDER  BY product_category, month),
     og
      AS (SELECT month,
                product_category,
                tpo,
                LAG(tpo) OVER (PARTITION BY product_category ORDER BY month) AS previous_month_order,
                CASE WHEN LAG(tpo) OVER (PARTITION BY product_category ORDER BY month) IS NOT NULL 
                     THEN CONCAT(ROUND(( tpo - LAG(tpo) OVER (PARTITION BY product_category ORDER BY month) ) / 
                                      LAG(tpo) OVER (PARTITION BY product_category ORDER BY MONTH), 3) * 100.0, '%')
                  ELSE NULL
                END AS order_growth
         FROM   (SELECT Format_date('%Y-%m', orders.created_at)        AS MONTH,
                        products.category                              AS
                        Product_category,
                        CAST(COUNT(order_items.product_id) AS FLOAT64) AS TPO
                 FROM   bigquery-public-data.thelook_ecommerce.orders AS orders
                        JOIN bigquery-public-data.thelook_ecommerce.order_items
                             AS
                             order_items
                          ON orders.user_id = order_items.user_id
                        JOIN bigquery-public-data.thelook_ecommerce.products AS
                             products
                          ON order_items.product_id = products.id
                 GROUP  BY 1, 2
                 ORDER  BY 1, 2) a
         ORDER  BY product_category, MONTH),
     tab
     AS (SELECT Format_date('%Y-%m', orders.created_at)                                   AS MONTH,
                EXTRACT(YEAR FROM orders.created_at)                                      AS YEAR,
                products.category                                                         AS Product_category,
                Sum(order_items.sale_price)                                               AS TPV,
                COUNT(order_items.product_id)                                             AS TPO,
                Sum(products.cost)                                                        AS total_cost,
                Sum(order_items.sale_price) - Sum(products.cost)                          AS total_profit,
                ( Sum(order_items.sale_price) - Sum(products.cost) ) / Sum(products.cost) AS profit_to_cost_ratio
         FROM   bigquery-public-data.thelook_ecommerce.orders AS orders
                JOIN bigquery-public-data.thelook_ecommerce.order_items AS order_items
                  ON orders.user_id = order_items.user_id
                JOIN bigquery-public-data.thelook_ecommerce.products AS products
                  ON order_items.product_id = products.id
         GROUP  BY 1, 2, 3
         ORDER  BY 1, 2, 3)
SELECT tab.MONTH,
       tab.year,
       tab.product_category,
       tab.tpv,
       tab.tpo,
       rg.revenue_growth,
       og.order_growth,
       tab.total_cost,
       tab.total_profit,
       tab.profit_to_cost_ratio
FROM   tab
       JOIN rg
         ON tab.MONTH = rg.MONTH
            AND tab.product_category = rg.product_category
       JOIN og
         ON tab.MONTH = og.MONTH
            AND tab.product_category = og.product_category
ORDER  BY 1, 2, 3; 

--2. Cohort Analyst
WITH convert
     AS (SELECT orders.order_id,
                orders.user_id,
                order_items.product_id,
                orders.created_at  AS DATE,
                orders.num_of_item AS quantity,
                order_items.sale_price
         FROM   bigquery-public-data.thelook_ecommerce.orders AS orders
                JOIN bigquery-public-data.thelook_ecommerce.order_items AS order_items
                  ON orders.order_id = order_items.order_id
         WHERE  orders.status = 'Complete'
                AND orders.user_id IS NOT NULL
                AND orders.num_of_item > 0
                AND order_items.sale_price > 0),
     main
     AS (SELECT *
         FROM   (SELECT *,
                        ROW_NUMBER()
                          OVER (PARTITION BY order_id, product_id, quantity ORDER BY DATE) AS stt
                 FROM   convert
                 ORDER  BY DATE) AS a
         WHERE  stt = 1),
     indexm
     AS (SELECT user_id,
                amount,
                Format_date('%Y-%m', first_purchase_date) AS cohort_date,
                DATE,
                (EXTRACT(YEAR FROM DATE) - EXTRACT(YEAR FROM first_purchase_date) )*12 + 
                (EXTRACT(MONTH FROM DATE) - EXTRACT(MONTH FROM first_purchase_date)) + 1 AS index
         FROM   (SELECT user_id,
                        sale_price * quantity     AS amount,
                        Min(DATE) OVER(PARTITION BY user_id) AS first_purchase_date,
                        DATE
                 FROM   main) a),
     cohort
     AS (SELECT cohort_date,
                index,
                COUNT(DISTINCT user_id) AS cnt,
                SUM(amount)             AS revenue
         FROM   indexm
         GROUP  BY 1,
                   2),
--customer cohort
     customer
     AS (SELECT cohort_date,
                Sum(CASE
                      WHEN index = 1 THEN cnt
                      ELSE 0
                    END) AS m1,
                Sum(CASE
                      WHEN index = 2 THEN cnt
                      ELSE 0
                    END) AS m2,
                Sum(CASE
                      WHEN index = 3 THEN cnt
                      ELSE 0
                    END) AS m3,
                Sum(CASE
                      WHEN index = 4 THEN cnt
                      ELSE 0
                    END) AS m4
         FROM   cohort
         GROUP  BY cohort_date),
--retention cohort
     retention
     AS (SELECT cohort_date,
                CONCAT(Round(100.00 * m1 / m1), "%") AS m1,
                CONCAT(Round(100.00 * m2 / m1), "%") AS m2,
                CONCAT(Round(100.00 * m3 / m1), "%") AS m3,
                CONCAT(Round(100.00 * m4 / m1), "%") AS m4
         FROM   customer)
--churn cohort
SELECT cohort_date,
       CONCAT(100 - Round(100.00 * m1 / m1), "%") AS m1,
       CONCAT(100 - Round(100.00 * m2 / m1), "%") AS m2,
       CONCAT(100 - Round(100.00 * m3 / m1), "%") AS m3,
       CONCAT(100 - Round(100.00 * m4 / m1), "%") AS m4
FROM   customer 
