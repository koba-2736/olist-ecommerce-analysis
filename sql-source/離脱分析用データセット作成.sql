WITH user_first_order AS (
  -- 1. 各ユーザーの初回注文を特定
  SELECT
    c.customer_unique_id,
    MIN(o.order_purchase_timestamp) AS first_order_time
  FROM `olist-492505.Olist.orders_dataset` o
  JOIN `olist-492505.Olist.customers` c ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
),

first_order_details AS (
  -- 2. 初回注文時の詳細を取得
  SELECT
    f.customer_unique_id,
    f.first_order_time,
    o.order_id,
    SUM(oi.price+oi.freight_value) AS initial_price,
    MAX(p.product_category_name) AS first_category,
    -- 注文から到着までの日数を計算
    DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_purchase_timestamp), DAY) AS delivery_days
  FROM user_first_order f
  JOIN `olist-492505.Olist.customers` c ON f.customer_unique_id = c.customer_unique_id
  JOIN `olist-492505.Olist.orders_dataset` o ON c.customer_id = o.customer_id 
    AND f.first_order_time = o.order_purchase_timestamp
  JOIN `olist-492505.Olist.order_items` oi ON o.order_id = oi.order_id
  JOIN `olist-492505.Olist.products_dataset` p ON oi.product_id = p.product_id
  -- delivery_daysの計算に必要なカラムをGROUP BYに追加
  GROUP BY 1, 2, 3, o.order_delivered_customer_date, o.order_purchase_timestamp
),

labels AS (
  -- 3. 2回目以降の注文があるか判定
  SELECT
    f.customer_unique_id,
    CASE WHEN COUNT(o.order_id) > 1 THEN 0 ELSE 1 END AS is_churn
  FROM user_first_order f
  JOIN `olist-492505.Olist.customers` c ON f.customer_unique_id = c.customer_unique_id
  JOIN `olist-492505.Olist.orders_dataset` o ON c.customer_id = o.customer_id
  GROUP BY 1
)

SELECT
  d.initial_price,
  d.first_category,
  d.delivery_days,
  l.is_churn
FROM first_order_details d
JOIN labels l ON d.customer_unique_id = l.customer_unique_id
