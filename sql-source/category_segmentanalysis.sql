WITH category_base as (
    SELECT
    od.order_id,
    c.customer_unique_id,
    od.order_purchase_timestamp,
    ARRAY_AGG(p.product_category_name ORDER BY (oi.price + oi.freight_value) DESC )[OFFSET(0)] as main_category,
    SUM(oi.price + oi.freight_value) AS order_amount
  FROM `olist-492505.Olist.orders_dataset` od
  JOIN `olist-492505.Olist.order_items` oi
    ON od.order_id = oi.order_id
  JOIN `olist-492505.Olist.customers` c
    ON od.customer_id = c.customer_id
  JOIN `olist-492505.Olist.products_dataset` p
    ON oi.product_id = p.product_id
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
    FROM category_base
  )
  WHERE rn = 1
),
repeat_flag as (
  SELECT
    customer_unique_id,
    CASE WHEN COUNT(order_id) >= 2 THEN 1 ELSE 0 END AS is_repeat
  FROM category_base
  GROUP BY customer_unique_id
),
final as (
  SELECT
    f.customer_unique_id,
    f.order_amount AS first_order_amount,
    r.is_repeat,
    main_category
  FROM first_order f
  JOIN repeat_flag r
    ON f.customer_unique_id = r.customer_unique_id
)
SELECT
 main_category,
 COUNT(*) AS users,
 CASE
  WHEN COUNT(*)<100  THEN 'low'
  WHEN COUNT(*)>1000 THEN 'high'
 ELSE 'medium'
 END AS user_segment,
 AVG(is_repeat) AS repeat_rate
FROM
 final
GROUP BY
 main_category
ORDER BY
 user_segment,repeat_rate DESC
