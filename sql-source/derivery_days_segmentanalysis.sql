WITH base as (
  SELECT
    c.customer_unique_id,
    od.order_id,
    od.order_purchase_timestamp,
    od.order_delivered_customer_date,
    DATE_DIFF(
      DATE(od.order_delivered_customer_date),
      DATE(od.order_purchase_timestamp),
      DAY
    ) as delivery_days
  FROM `olist-492505.Olist.orders_dataset` od
  JOIN `olist-492505.Olist.customers` c
    ON od.customer_id = c.customer_id
  WHERE od.order_status = 'delivered'
),

order_level as (
  SELECT
    customer_unique_id,
    order_id,
    delivery_days
  FROM base
),

first_order as (
  SELECT *
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_id
      ) as rn
    FROM order_level
  )
  WHERE rn = 1
),

repeat_flag as (
  SELECT
    customer_unique_id,
    CASE WHEN COUNT(order_id) >= 2 THEN 1 ELSE 0 END as is_repeat
  FROM order_level
  GROUP BY customer_unique_id
),

final as (
  SELECT
    f.customer_unique_id,
    f.delivery_days,
    r.is_repeat
  FROM first_order f
  JOIN repeat_flag r
    ON f.customer_unique_id = r.customer_unique_id
)

SELECT
  CASE
    WHEN delivery_days <= 3 THEN 'fast(<=3)'
    WHEN delivery_days <= 7 THEN 'normal(4-7)'
    WHEN delivery_days <= 14 THEN 'slow(8-14)'
    ELSE 'very_slow(15+)'
  END as delivery_segment,
  COUNT(*) as users,
  AVG(is_repeat) as repeat_rate
FROM final
GROUP BY delivery_segment
ORDER BY repeat_rate DESC
