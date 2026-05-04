SELECT 
 COUNT(DISTINCT oi.order_id) AS order_count,
 COUNT(DISTINCT c.customer_unique_id) as customer_count,
 SUM(price)+SUM(freight_value) as total_sales,
 (SUM(price)+SUM(freight_value))/COUNT(DISTINCT c.customer_unique_id) as unit_price,
 COUNT(DISTINCT oi.order_id)/COUNT(DISTINCT c.customer_unique_id) as purchase_freqency
FROM `olist-492505.Olist.order_items`  as oi
 JOIN `olist-492505.Olist.orders_dataset` as od on od.order_id = oi.order_id
 JOIN `olist-492505.Olist.customers` as c on od.customer_id = c.customer_id
WHERE od.order_status = 'delivered'
