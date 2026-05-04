--購入ユーザーごとに初回購入月を表示
WITH first_orders as (
SELECT 
    c.customer_unique_id,
    MIN(DATE_TRUNC(DATE(od.order_purchase_timestamp), MONTH)) as first_order_month
  FROM `olist-492505.Olist.orders_dataset` od
  JOIN `olist-492505.Olist.customers` c
    ON od.customer_id = c.customer_id
  WHERE od.order_status = 'delivered'
  GROUP BY c.customer_unique_id
),
--単に購入ユーザーとその購入月を表示
all_orders as (
  SELECT 
    c.customer_unique_id,
    DATE_TRUNC(DATE(od.order_purchase_timestamp), MONTH) as order_month
  FROM `olist-492505.Olist.orders_dataset` od
  JOIN `olist-492505.Olist.customers` c
    ON od.customer_id = c.customer_id
  WHERE od.order_status = 'delivered'
),
--上記2表を結合して、ユーザーと購入月でグループ化してナンバリング
orderflagged as(
SELECT
 ao.customer_unique_id,
 order_month,
 first_order_month
FROM all_orders as ao
JOIN first_orders as fo
 ON ao.customer_unique_id = fo.customer_unique_id
ORDER BY order_month
)
SELECT
  first_order_month,
  DATE_DIFF(order_month, first_order_month, MONTH) as month_diff,
  COUNT(DISTINCT customer_unique_id) as users
FROM orderflagged
GROUP BY
  first_order_month,
  month_diff
ORDER BY
  first_order_month,
  month_diff