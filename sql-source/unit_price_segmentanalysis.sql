WITH order_amount as (
    SELECT
    od.order_id,
    c.customer_unique_id,
    od.order_purchase_timestamp,
    SUM(oi.price + oi.freight_value) AS order_amount
  FROM `olist-492505.Olist.orders_dataset` od
  JOIN `olist-492505.Olist.order_items` oi
    ON od.order_id = oi.order_id
  JOIN `olist-492505.Olist.customers` c
    ON od.customer_id = c.customer_id
  WHERE od.order_status = 'delivered'
  GROUP BY od.order_id, customer_unique_id, order_purchase_timestamp
),
first_order as (
  SELECT *
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchase_timestamp
      ) AS rn
    FROM order_amount
  )
  WHERE rn = 1
),
repeat_flag as (
  SELECT
    customer_unique_id,
    CASE WHEN COUNT(order_id) >= 2 THEN 1 ELSE 0 END AS is_repeat
  FROM order_amount
  GROUP BY customer_unique_id
),
final as (
  SELECT
    f.customer_unique_id,
    f.order_amount AS first_order_amount,
    r.is_repeat,
    CASE
      WHEN f.order_amount < 300 THEN 'low'
      WHEN f.order_amount < 1000 THEN 'mid'
      ELSE 'high'
    END AS price_segment
  FROM first_order f
  JOIN repeat_flag r
    ON f.customer_unique_id = r.customer_unique_id
)
SELECT
  price_segment,
  COUNT(*) AS users,
  AVG(is_repeat) AS repeat_rate
FROM final
GROUP BY price_segment
ORDER BY price_segment