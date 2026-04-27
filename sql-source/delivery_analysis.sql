CREATE OR REPLACE VIEW `olist-492505.Olist.analysis_delivery_performance` AS
WITH delivery_base AS (
  SELECT
    c.customer_unique_id,
    od.order_id,
    -- 配送日数の計算（配送完了 - 購入日）
    DATE_DIFF(DATE(od.order_delivered_customer_date), DATE(od.order_purchase_timestamp), DAY) AS delivery_days,
    -- ユーザーごとの購入順序（1枚目と同じロジック）
    ROW_NUMBER() OVER(PARTITION BY c.customer_unique_id ORDER BY od.order_purchase_timestamp) AS order_sequence
  FROM `olist-492505.Olist.orders_dataset` od
  JOIN `olist-492505.Olist.customers` c ON od.customer_id = c.customer_id
  WHERE od.order_status = 'delivered'
    AND od.order_delivered_customer_date IS NOT NULL
)
SELECT
  -- 配送日数をグループ化（CASE文で階級分け）
  CASE 
    WHEN delivery_days <= 5 THEN '01: 0-5日'
    WHEN delivery_days <= 10 THEN '02: 6-10日'
    WHEN delivery_days <= 15 THEN '03: 11-15日'
    WHEN delivery_days <= 20 THEN '04: 16-20日'
    ELSE '05: 21日以上'
  END AS delivery_group,
  COUNT(DISTINCT order_id) AS total_orders,
  -- そのグループの中で「リピート購入（2回目以降）」だった数
  COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN customer_unique_id END) AS repeat_customers,
  SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN customer_unique_id END),COUNT(DISTINCT order_id)) as repeat_rate
FROM delivery_base
GROUP BY 1
ORDER BY 1;
