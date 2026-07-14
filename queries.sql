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
