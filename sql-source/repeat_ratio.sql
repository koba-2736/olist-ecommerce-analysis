WITH repeat_ratio as(
  SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT od.order_id) as total_orders,
    CASE WHEN COUNT(DISTINCT od.order_id) > 1 THEN 1 ELSE 0 END AS is_repeat
  FROM `olist-492505.Olist.orders_dataset` as od
  JOIN `olist-492505.Olist.customers` as c
    ON od.customer_id = c.customer_id
  WHERE od.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
SELECT
  COUNT(*) as total_customers,
  SUM(is_repeat) as repeat_customers,
  SUM(is_repeat)/COUNT(*) as repeat_rate
FROM repeat_ratio
