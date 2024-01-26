# Ecommerce Dataset: Exploratory Data Analysis (EDA) and Cohort Analysis in SQL

## I. Tổng quan về dữ liệu
TheLook là một trang web thương mại điện tử về quần áo. Tập dữ liệu chứa thông tin về customers, products, orders, logistics, web events , digital marketing campaigns.

Link dataset: [theLook Ecommerce](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce?q=search&referrer=search&project=sincere-torch-350709)

- Bảng Orders : ghi lại tất cả các đơn hàng mà khách hàng đã đặt

- Bảng Order_items : ghi lại danh sách các mặt hàng đã mua trong mỗi order ID.

- Bảng Products : ghi lại chi tiết các sản phẩm được bán trên The Look, bao gồm price, brand, & product categories.

## II. Ad-hoc tasks
1. Số lượng đơn hàng và số lượng khách hàng mỗi tháng:
  
  Thống kê tổng số lượng người mua và số lượng đơn hàng đã hoàn thành mỗi tháng (Từ 1/2019-4/2022)

2. Giá trị đơn hàng trung bình (AOV) và số lượng khách hàng mỗi tháng

  Thống kê giá trị đơn hàng trung bình và tổng số người dùng khác nhau mỗi tháng (Từ 1/2019-4/2022)

3. Nhóm khách hàng theo độ tuổi

  Tìm các khách hàng có trẻ tuổi nhất và lớn tuổi nhất theo từng giới tính (Từ 1/2019-4/2022)

4. Top 5 sản phẩm mỗi tháng.
  
  Thống kê top 5 sản phẩm có lợi nhuận cao nhất từng tháng (xếp hạng cho từng sản phẩm). 

5. Doanh thu tính đến thời điểm hiện tại trên mỗi danh mục

  Thống kê tổng doanh thu theo ngày của từng danh mục sản phẩm (category) trong 3 tháng qua (giả sử ngày hiện tại là 15/4/2022)

## III.  Cohort Analysis.

### Tổng quan về Cohort Analysis
Cohort analysis là một phương pháp trong lĩnh vực phân tích dữ liệu để theo dõi và đánh giá hành vi của một nhóm người dùng (cohort) qua thời gian. Một cohort là một nhóm người dùng có những đặc tính chung hoặc trải qua một sự kiện chung trong một khoảng thời gian nhất định. Phân tích cohort giúp ta hiểu rõ hơn về sự thay đổi trong hành vi của người dùng theo thời gian và theo các yếu tố nhất định.

Các ứng dụng phổ biến của cohort analysis bao gồm:

1. **Retention Analysis:** Theo dõi tỷ lệ giữ chân (retention rate) của các nhóm người dùng theo thời gian. Điều này giúp hiểu xem bao nhiêu người dùng ở lại sau một khoảng thời gian cụ thể.

2. **Churn Analysis:** Phân tích tỷ lệ chuyển đổi (churn rate) để đánh giá tỷ lệ người dùng bỏ đi trong các cohort cụ thể.

3. **Behavior Analysis:** Theo dõi hành vi của các nhóm người dùng qua thời gian để hiểu cách họ tương tác với sản phẩm hoặc dịch vụ.

4. **Revenue Analysis:** Xem xét doanh thu và giá trị customer lifetime value (CLV) theo cohort để hiểu giá trị của các nhóm người dùng khác nhau.

5. **Product Adoption:** Theo dõi sự tiếp cận và sử dụng sản phẩm hoặc tính năng mới theo từng nhóm người dùng khác nhau.

Cohort analysis giúp các doanh nghiệp và nhà nghiên cứu hiểu rõ hơn về sự thay đổi theo thời gian và cung cấp thông tin quan trọng để điều chỉnh chiến lược kinh doanh và marketing.

### Yêu cầu:

Cần dựng dashboard Cohort Analysis và có yêu cầu xử lý dữ liệu trước khi kết nối với BI tool. 

Các metric cần thiết cho dashboard và cần phải trích xuất dữ liệu từ database để ra được 1 dataset như mô tả:

| STT | Tên trường dữ liệu | Tên bảng dữ liệu mong muốn lấy thông tin | Mô tả |
|----|-------------------|--------------------------------------|------|
| 1  | Month             | Bảng orders (Tháng của năm dữ liệu)   | Định dạng yyyy-mm |
| 2  | Year              | Bảng orders                          | Năm |
| 3  | Product_category  | Bảng product                         |      |
| 4  | TPV               | Bảng orders_items                    | Tổng doanh thu mỗi tháng |
| 5  | TPO               | Bảng orders_items                    | Tổng số đơn hàng mỗi tháng |
| 6  | Revenue_growth    | Trường phái sinh                     | (doanh thu tháng sau-doanh thu tháng trước)/doanh thu tháng trước | Hiển thị dạng % |
| 7  | Order_growth      | Trường phái sinh                     | (số đơn hàng tháng sau - số đơn hàng tháng trước)/số đơn tháng trước | Hiển thị dạng % |
| 8  | Total_cost        | Bảng products                       | Tổng chi phí mỗi tháng |
| 9  | Total_profit      | Trường phái sinh                     | Tổng doanh thu - tổng chi phí | Tổng lợi nhuận mỗi tháng |
| 10 | Profit_to_cost_ratio | Trường phái sinh                   | Tổng lợi nhuận/ tổng chi phí | Tỉ lệ lợi nhuân/chi phí mỗi tháng |



