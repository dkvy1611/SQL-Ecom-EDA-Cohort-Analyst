--1. Tổng số lượng người mua và số lượng đơn hàng đã hoàn thành mỗi tháng ( Từ 1/2019-4/2022)
SELECT FORMAT_DATE('%Y-%m', created_at) AS month_year,
       COUNT(DISTINCT user_id)          AS total_user,
       COUNT(order_id)                  AS total_order
FROM   bigquery-public-data.thelook_ecommerce.orders
WHERE  status = 'Complete'
       AND created_at BETWEEN TIMESTAMP('2019-01-01') AND
                              TIMESTAMP('2022-04-30')
GROUP  BY 1
ORDER  BY 1; 
/* Insight: Lượng khách hàng và đơn hàng có xu hướng tăng dần theo thời gian. Gần như toàn bộ các khách hàng đều chỉ đặt 1 đơn hàng mỗi tháng. 
-> Có thể cho thấy chiến lược tiếp thị, quảng cáo hoặc chiến dịch kích thích mua hàng đang mang lại kết quả tích cực và đưa vào được nhiều khách hàng mới.*/

--2. Giá trị đơn hàng trung bình và tổng số người dùng khác nhau mỗi tháng 
SELECT FORMAT_DATE('%Y-%m', created_at)  AS month_year,
       COUNT(DISTINCT user_id)           AS distinct_users,
       SUM(sale_price) / COUNT(order_id) AS average_order_value
FROM   bigquery-public-data.thelook_ecommerce.order_items
WHERE  created_at BETWEEN TIMESTAMP('2019-01-01') AND TIMESTAMP('2022-04-30')
GROUP  BY 1
ORDER  BY 1 ;
/*Insight: tổng số người dùng khác nhau mỗi tháng có xu hướng tăng nhanh nhưng giá trị đơn hàng trung bình không tăng mà chỉ giao động quanh mức 60. Có thể xem xét một số nguyên nhân sau:
- Do chiến lược giảm giá hoặc khuyến mại:  Có thể do doanh nghiệp áp dụng nhiều chương trình giảm giá hoặc khuyến mãi để thu hút người dùng mới. Điều này có thể dẫn đến việc giảm giá trị đơn hàng trung bình.
- Chất lượng sản phẩm không tăng: Nếu chất lượng sản phẩm hoặc dịch vụ không tăng, có thể khách hàng không có động lực để mua nhiều hơn hoặc chi trả nhiều hơn cho mỗi đơn hàng.
- Chính sách giá không thay đổi: Nếu doanh nghiệp không áp dụng các chính sách giá mới hoặc các chiến lược tăng giá, giá trị đơn hàng trung bình có thể giữ nguyên.
*/

--3. Nhóm khách hàng theo độ tuổi (Từ 1/2019-4/2022)
WITH youngest
     AS (SELECT first_name,
                last_name,
                gender,
                age,
                'youngest' AS tag
         FROM   bigquery-public-data.thelook_ecommerce.users
         WHERE  created_at BETWEEN TIMESTAMP('2019-01-01') AND TIMESTAMP('2022-04-30')
                AND age IN (SELECT Min(age) AS age
                            FROM   bigquery-public-data.thelook_ecommerce.users
                            WHERE  created_at BETWEEN TIMESTAMP('2019-01-01') AND TIMESTAMP('2022-04-30')
                            GROUP  BY gender)
         ORDER  BY 1, 2),
     oldest
     AS (SELECT first_name,
                last_name,
                gender,
                age,
                'oldest' AS tag
         FROM   bigquery-public-data.thelook_ecommerce.users
         WHERE  created_at BETWEEN TIMESTAMP('2019-01-01') AND TIMESTAMP('2022-04-30')
                AND age IN (SELECT Max(age) AS age
                            FROM   bigquery-public-data.thelook_ecommerce.users
                            WHERE  created_at BETWEEN TIMESTAMP('2019-01-01') AND TIMESTAMP('2022-04-30')
                            GROUP  BY gender)
         ORDER  BY 1, 2),
     age
     AS (SELECT *
         FROM   youngest
         UNION ALL
         SELECT *
         FROM   oldest)
--Số lượng khách hàng trẻ nhất và lớn tuổi nhất:
SELECT tag,
       COUNT(*)
FROM   age
GROUP  BY tag; 
/*Insight: khách hàng trẻ nhất: 12 tuổi - 1111 người. Khách hàng lớn tuổi nhất: 70 tuổi - 1107 người.
-> Tệp khách hàng phân phối ở đa dạng độ tuổi;
-> Chiến lược tiếp thị hiệu quả, giữ chân được cả người trẻ và người lón tuổi
-> Có tiềm năng tăng trưởng trong tất cả các phân khúc độ tuổi */

--4. Top 5 sản phẩm mỗi tháng.
WITH top5
     AS (SELECT month_year,
                product_id,
                product_name,
                sales,
                cost,
                profit,
                DENSE_RANK()
                  OVER(
                    PARTITION BY month_year
                    ORDER BY profit) AS rank_per_month
         FROM   (SELECT Format_date('%Y-%m', b.created_at) AS month_year,
                        a.id                               AS product_id,
                        a.name                             AS product_name,
                        Round(b.sale_price, 2)             AS sales,
                        Round(a.cost, 2)                   AS cost,
                        Round(a.retail_price - a.cost, 2)  AS profit
                 FROM   bigquery-public-data.thelook_ecommerce.products AS a
         INNER JOIN bigquery-public-data.thelook_ecommerce.order_items AS b
         ON a.id = b.product_id
                 WHERE  b.created_at BETWEEN TIMESTAMP('2019-01-01') AND
                                             TIMESTAMP('2022-04-30')
                 ORDER  BY 1) a)
SELECT *
FROM   top5
WHERE  rank_per_month <= 5
ORDER  BY month_year; 

--5. Doanh thu tính đến thời điểm hiện tại trên mỗi danh mục
SELECT *
FROM   bigquery-public-data.thelook_ecommerce.order_items;

SELECT Format_date('%Y-%m-%d', b.created_at) AS dates,
       a.category                            AS product_category,
       Round(Sum(a.retail_price), 2)         AS revenue
FROM   bigquery-public-data.thelook_ecommerce.products AS a
JOIN bigquery-public-data.thelook_ecommerce.order_items AS b
ON a.id = b.product_id
WHERE  b.created_at BETWEEN TIMESTAMP('2022-01-15') AND TIMESTAMP('2022-04-15')
GROUP  BY 1, 2
ORDER  BY 1, 2; 
