-- 1.1. Порахуйте загальну чисту виручку (net_amount), кількість замовлень і середній чек по кожному РЕГІОНУ за кожен РІК. Потрібен JOIN orders з customers.
SELECT
    c.region,
    o.order_year,
    ROUND(SUM(o.net_amount), 2) AS total_net_revenue,
    COUNT(o.order_id) AS order_count,
    ROUND(AVG(o.net_amount), 2) AS average_order_value
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY
    c.region,
   o.order_year
ORDER BY
    o.order_year,
    total_net_revenue DESC;


-- 1.2. Знайдіть топ-10 клієнтів за загальною сумою витрат. Виведіть їхній регіон, канал залучення і скільки замовлень вони зробили.
SELECT
    c.customer_id,
    c.region,
    c.acquisition_chan,
    ROUND(SUM(o.net_amount), 2) AS total_spend,
    COUNT(o.order_id) AS order_count,
    ROUND(AVG(o.net_amount), 2) AS average_order_value
FROM customers AS c
INNER JOIN orders AS o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.region,
    c.acquisition_chan


    -- 1.3. Для кожної категорії товарів порахуйте: загальну виручку, середню маржу (margin_pct) і частку повернень. Потрібно об'єднати order_items, products та orders.
SELECT
    p.category,
    ROUND(SUM(oi.line_total), 2) AS total_item_revenue,
    ROUND(
        SUM(p.margin_pct * oi.line_total)
        / NULLIF(SUM(oi.line_total), 0),
        2
    ) AS avg_margin_pct,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(
        DISTINCT CASE
            WHEN o.is_returned = 1 THEN o.order_id
        END
    ) AS returned_order_count,
    ROUND(
        100.0
        * COUNT(
            DISTINCT CASE
                WHEN o.is_returned = 1 THEN o.order_id
            END
        )
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS return_rate_pct

FROM order_items AS oi
INNER JOIN products AS p
    ON oi.product_id = p.product_id
INNER JOIN orders AS o
    ON oi.order_id = o.order_id
GROUP BY
    p.category
ORDER BY
    total_item_revenue DESC;
ORDER BY
    total_spend DESC
LIMIT 10;

-- 1.4.1 За допомогою підзапиту знайдіть клієнтів, чия загальна сума витрат перевищує середню суму витрат по всій базі. 
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.region,
        c.acquisition_chan,
        COUNT(o.order_id) AS order_count,
        COALESCE(SUM(o.net_amount), 0) AS total_spend
    FROM customers AS c
    LEFT JOIN orders AS o
        ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id,
        c.region,
        c.acquisition_chan
)
SELECT
    customer_id,
    region,
    acquisition_chan,
    order_count,
    ROUND(total_spend, 2) AS total_spend
FROM customer_spend
WHERE total_spend > (
    SELECT AVG(total_spend)
    FROM customer_spend
)
ORDER BY
    total_spend DESC;

-- 1.4.2 Скільки їх? Яка їхня частка у загальній виручці?
WITH customer_spend AS (
    SELECT
        c.customer_id,
        COALESCE(SUM(o.net_amount), 0) AS total_spend
    FROM customers AS c
    LEFT JOIN orders AS o
        ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id
)
SELECT
    COUNT(*) AS above_average_customer_count,
    ROUND(
        (
            SELECT AVG(total_spend)
            FROM customer_spend
        ),
        2
    ) AS average_customer_spend,
    ROUND(SUM(total_spend), 2) AS above_average_customer_revenue,
    ROUND(
        (
            SELECT SUM(total_spend)
            FROM customer_spend
        ),
        2
    ) AS total_revenue,
    ROUND(
        100.0 * SUM(total_spend)
        / NULLIF(
            (
                SELECT SUM(total_spend)
                FROM customer_spend
            ),
            0
        ),
        2
    ) AS revenue_share_pct
FROM customer_spend
WHERE total_spend > (
    SELECT AVG(total_spend)
    FROM customer_spend
);

-- 1.5 Порахуйте для кожного маркетингового каналу: сумарний бюджет, сумарну приписану виручку і ROI (виручка / бюджет). Використайте таблицю marketing.
SELECT
    channel,
    ROUND(SUM(budget), 2) AS total_budget,
    ROUND(SUM(attributed_reven), 2) AS total_attributed_revenue,
    ROUND(
        1.0 * SUM(attributed_reven)
        / NULLIF(SUM(budget), 0),
        2
    ) AS roas,
    ROUND(
        100.0
        * (SUM(attributed_reven) - SUM(budget))
        / NULLIF(SUM(budget), 0),
        2
    ) AS roi_pct
FROM marketing
GROUP BY
    channel
ORDER BY
    roas DESC;
