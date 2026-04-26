CREATE OR REPLACE VIEW `olist-492505.Olist.summary_monthly_kpis` AS
WITH orders_with_rank AS (
  -- すべての注文に対して、そのユーザーにとって「何回目の注文か」を振る
  SELECT
    od.order_id,
    c.customer_unique_id,
    DATE_TRUNC(DATE(od.order_purchase_timestamp), MONTH) AS order_month,
    oi.price,
    -- ここがポイント：全期間で並べて、各注文に番号を振る
    ROW_NUMBER() OVER(PARTITION BY c.customer_unique_id ORDER BY od.order_purchase_timestamp) AS order_sequence
  FROM `olist-492505.Olist.orders_dataset` od
  JOIN `olist-492505.Olist.order_items` oi ON od.order_id = oi.order_id
  JOIN `olist-492505.Olist.customers` c ON od.customer_id = c.customer_id
  WHERE od.order_status = 'delivered'
)
SELECT
  order_month,
  SUM(price) AS total_revenue,
  COUNT(DISTINCT order_id) AS total_orders,
  COUNT(DISTINCT customer_unique_id) AS total_customers,
  -- order_sequence が 2 以上の注文はすべて「リピート購入」
  COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN customer_unique_id END) AS repeat_customers,
  -- リピート率（その月の購入者のうち、2回目以降の人が何割か）
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN customer_unique_id END),
    COUNT(DISTINCT customer_unique_id)
  ) AS repeat_rate
FROM orders_with_rank
GROUP BY order_month
ORDER BY order_month DESC;