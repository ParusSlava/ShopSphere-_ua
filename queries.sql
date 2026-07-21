-- 1.1. Порахуйте загальну чисту виручку (net_amount), кількість замовлень і середній чек по кожному РЕГІОНУ за кожен РІК. Потрібен JOIN orders з customers.
SELECT
    c.region,
    o.order_year,
    COUNT(o.order_id)                      AS orders_count,
    ROUND(SUM(o.net_amount), 2)            AS total_net_revenue,
    ROUND(AVG(o.net_amount), 2)            AS avg_order_value
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY
    c.region,
    o.order_year
ORDER BY
    c.region,
    o.order_year;

-- 1.2. Знайдіть топ-10 клієнтів за загальною сумою витрат. Виведіть їхній регіон, канал залучення і скільки замовлень вони зробили.
SELECT
    c.customer_id,
    c.region,
    c.acquisition_chan,
    COUNT(o.order_id)               AS total_orders,
    ROUND(SUM(o.net_amount), 2)     AS total_spent
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.region,
    c.acquisition_chan
ORDER BY
    total_spent DESC
LIMIT 10;


    -- 1.3. Для кожної категорії товарів порахуйте: загальну виручку, середню маржу (margin_pct) і частку повернень. Потрібно об'єднати order_items, products та orders.
WITH category_orders AS (
    -- Крок 1: для кожної пари (категорія, замовлення)
    -- фіксуємо, чи було замовлення повернене
    SELECT DISTINCT
        oi.category,
        oi.order_id,
        o.is_returned
    FROM order_items AS oi
    JOIN orders AS o
        ON oi.order_id = o.order_id
),

order_totals AS (
    -- Крок 2: рахуємо загальну суму товарів у кожному замовленні
    -- Це потрібно, щоб правильно розподілити Net Amount між категоріями
    SELECT
        order_id,
        SUM(line_total) AS order_items_total
    FROM order_items
    GROUP BY order_id
)

SELECT
    oi.category,

    -- Gross / Total Revenue
    ROUND(
        SUM(oi.line_total),
        2
    ) AS total_revenue,

    -- Net Revenue:
    -- Net Amount замовлення розподіляється між товарами
    -- пропорційно їх частці в сумі замовлення
    ROUND(
        SUM(
            CASE
                WHEN ot.order_items_total = 0 THEN 0
                ELSE
                    oi.line_total * o.net_amount
                    / ot.order_items_total
            END
        ),
        2
    ) AS total_net_revenue,

    -- Середня маржа категорії
    ROUND(
        AVG(p.margin_pct),
        2
    ) AS avg_margin_pct,

    -- Частка повернених замовлень категорії
    (
        SELECT COUNT(*)
        FROM category_orders co
        WHERE co.category = oi.category
          AND co.is_returned = 1
    ) * 1.0
    /
    (
        SELECT COUNT(*)
        FROM category_orders co2
        WHERE co2.category = oi.category
    ) AS return_rate

FROM order_items AS oi

JOIN orders AS o
    ON oi.order_id = o.order_id

JOIN products AS p
    ON oi.product_id = p.product_id

JOIN order_totals AS ot
    ON oi.order_id = ot.order_id

GROUP BY
    oi.category

ORDER BY
    total_net_revenue DESC;

-- 1.4.1 За допомогою підзапиту знайдіть клієнтів, чия загальна сума витрат перевищує середню суму витрат по всій базі. 
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(net_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
)
SELECT
    COUNT(*)                                                              AS customers_above_avg,
    ROUND(SUM(total_spent), 2)                                            AS revenue_above_avg,
    ROUND(
        SUM(total_spent) * 100.0 / (SELECT SUM(net_amount) FROM orders), 2
    )                                                                      AS pct_of_total_revenue
FROM customer_totals
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_totals);

-- 1.4.2 Скільки їх? Яка їхня частка у загальній виручці?


-- 1.5 Порахуйте для кожного маркетингового каналу: сумарний бюджет, сумарну приписану виручку і ROI (виручка / бюджет). Використайте таблицю marketing.
SELECT
    channel,
    ROUND(SUM(budget), 2)                                     AS total_budget,
    ROUND(SUM(attributed_reven), 2)                         AS total_attributed_revenue,
    ROUND(SUM(attributed_reven) * 1.0 / SUM(budget), 2)     AS roi
FROM marketing
GROUP BY channel
ORDER BY roi DESC;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


