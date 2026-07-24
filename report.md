# ShopSphere — аналіз глобального маркетплейсу

## Executive Summary

ShopSphere — аналітичний проєкт глобального маркетплейсу за 2022–2024 роки.

Мета — оцінити не лише зростання бізнесу, а й **якість цього зростання**: ефективність маркетингу, цінність клієнтів, привабливість категорій, регіональний потенціал і результат A/B-тесту checkout.

Основний аналітичний процес:

**Raw Data → SQL → Analytical Dataset → Python Statistics → Tableau → Business Decision**

Створено три фінальні Dashboard:

1. **CEO Dashboard** — загальна картина бізнесу.
2. **Marketing & Customer LTV Dashboard** — ефективність маркетингу та цінність клієнтів.
3. **A/B Test Checkout Dashboard** — статистична оцінка продуктового експерименту.

---

## Data & Methodology

Для аналізу використано п'ять основних таблиць:

| Таблиця | Призначення |
|---|---|
| `customers` | клієнти, регіони, країни, acquisition channel, signup date |
| `orders` | замовлення, device, discount, net amount, returns, A/B variant |
| `order_items` | товарні позиції всередині замовлення |
| `products` | товари, категорії, ціна, собівартість, margin |
| `marketing` | channel, budget, impressions, clicks, conversions, attributed revenue |

### Інструменти

**SQL**
- JOIN та агрегації;
- розрахунок KPI;
- сегментація клієнтів;
- window functions;
- Pareto-аналіз;
- підготовка датасетів для Tableau та A/B-тесту.

**Python / Google Colab**
- descriptive statistics;
- Welch t-test;
- 95% confidence intervals;
- p-values.

**Tableau**
- exploratory visualizations;
- KPI;
- інтерактивні фільтри;
- фінальні управлінські Dashboard.

---

# Блок 2. Exploratory Analysis

## 2.1. Сезонність та динаміка виручки

*Tableau: Saisonalität und Umsatzentwicklung — сезонність і динаміка виручки*

### Бізнес-питання

Як змінюється чиста виручка ShopSphere у часі та чи є повторювані сезонні піки?

### SQL-запит

```sql
SELECT
    order_year,
    order_month,
    printf('%04d-%02d-01', order_year, order_month) AS month_date,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(net_amount), 2) AS total_net_revenue
FROM orders
GROUP BY
    order_year,
    order_month
ORDER BY
    order_year,
    order_month;
```

### SQL-запит та результат у SQLiteOnline

![SQL-запит: місячна динаміка замовлень і чистої виручки](SQL/2.1_monthly_revenue.jpg)

Запит агрегує `orders` до рівня місяця та формує часовий ряд для Tableau.

### Візуалізація Tableau

![Сезонність та динаміка виручки](Tableau/2.1_Sansonalität.jpg)

### Ключовий результат

- виручка демонструє сильний довгостроковий ріст;
- листопад–грудень повторюються як сезонний пік;
- грудень 2024 року — приблизно **$759.4K**, максимум за весь період.

### Бізнес-висновок

ShopSphere варто заздалегідь готувати inventory, logistics, маркетингові кампанії та customer support до пікового навантаження наприкінці року.

---

## 2.2. Ефективність маркетингових каналів: Budget vs. ROI

*Tableau: Marketingeffizienz: Budget vs. ROI — ефективність маркетингу: бюджет проти ROI*

### Бізнес-питання

Які маркетингові канали найефективніше використовують бюджет?

У проєкті ROI розраховується як:

`Attributed Revenue / Marketing Budget`

Показник показує, скільки доларів атрибутованої виручки припадає на кожний $1 маркетингового бюджету.

> Технічно показник ближчий до ROAS, але в завданні та Tableau використовується назва ROI.

### SQL-запит

```sql
SELECT
    channel,
    ROUND(SUM(budget), 2) AS total_budget,
    ROUND(SUM(attributed_reven), 2) AS total_attributed_revenue,
    ROUND(
        1.0 * SUM(attributed_reven) / SUM(budget),
        2
    ) AS roi
FROM marketing
GROUP BY channel
ORDER BY roi DESC;
```

### SQL-запит та результат у SQLiteOnline

![SQL-запит і результат — Marketing Budget vs ROI](SQL/2.2_marketing%20budget%20vs%20roi.jpg)

### Результат

| Канал | Бюджет | Частка бюджету | Атрибутована виручка | ROI |
|---|---:|---:|---:|---:|
| Organic | $20,364 | 2.08% | $163,398 | 8.02 |
| Email | $37,468 | 3.82% | $243,610 | 6.50 |
| Influencer | $112,337 | 11.45% | $519,453 | 4.62 |
| Referral | $73,766 | 7.52% | $263,536 | 3.57 |
| Social Ads | $286,488 | 29.19% | $589,544 | 2.06 |
| Paid Search | $450,959 | 45.95% | $598,703 | 1.33 |

### Візуалізація Tableau

![Marketingeffizienz: Budget vs. ROI](Tableau/2.2_Marketing%20Budget%20vs%20ROI.jpg)

### Ключовий результат

- **Organic** — найвищий ROI: **8.02**;
- **Email** — ROI **6.50**;
- **Paid Search** отримує **45.95% бюджету**, але має найнижчий ROI — **1.33**.

### Бізнес-висновок

Paid Search не варто різко вимикати, оскільки він генерує великий абсолютний обсяг виручки.

Оптимальніше — **поетапно тестувати новий marketing mix**, поступово збільшуючи інвестиції в Organic, Email та Influencer і контролюючи marginal ROI, CAC та LTV.

---

## 2.3. Продуктивність категорій: виручка, маржа та повернення

*Tableau: Kategorienperformance: Nettoumsatz, Marge und Retouren — ефективність категорій: чиста виручка, маржа та повернення*

### Бізнес-питання

Які товарні категорії справді економічно привабливі, якщо одночасно врахувати чисту виручку, маржу та повернення?

### SQL-запит

```sql
WITH order_totals AS (
    SELECT
        order_id,
        SUM(line_total) AS order_items_total
    FROM order_items
    GROUP BY order_id
),

category_orders AS (
    SELECT DISTINCT
        oi.category,
        oi.order_id,
        o.is_returned
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
)

SELECT
    oi.category,

    ROUND(
        SUM(oi.line_total),
        2
    ) AS total_revenue,

    ROUND(
        SUM(
            CASE
                WHEN ot.order_items_total = 0 THEN 0
                ELSE oi.line_total * o.net_amount / ot.order_items_total
            END
        ),
        2
    ) AS total_net_revenue,

    ROUND(
        AVG(p.margin_pct),
        2
    ) AS avg_margin_pct,

    ROUND(
        100.0 *
        (
            SELECT COUNT(*)
            FROM category_orders co
            WHERE co.category = oi.category
              AND co.is_returned = 1
        )
        /
        (
            SELECT COUNT(*)
            FROM category_orders co
            WHERE co.category = oi.category
        ),
        2
    ) AS return_rate_pct

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN order_totals ot
    ON oi.order_id = ot.order_id

GROUP BY oi.category
ORDER BY total_net_revenue DESC;
```

### SQL-запит та результат у SQLiteOnline

![SQL-запит і результат — продуктивність категорій](SQL/2.3.%20Kategorienperformance.jpg)

Оскільки одне замовлення може містити товари з різних категорій, `net_amount` пропорційно розподіляється між товарними позиціями. Це дозволяє уникнути подвійного підрахунку чистої виручки після JOIN.

### Результат

| Категорія | Чиста виручка | Середня маржа | Повернення |
|---|---:|---:|---:|
| Electronics | $1,986,033.63 | 12% | 15.97% |
| Home & Kitchen | $549,700.83 | 35% | 10.27% |
| Sports | $325,674.21 | 30% | 8.40% |
| Clothing | $235,044.76 | 45% | 16.00% |
| Beauty | $159,176.17 | 55% | 9.97% |
| Toys | $132,623.76 | 40% | 8.98% |
| Books | $85,762.67 | 25% | 8.13% |

### Візуалізація Tableau

![Продуктивність категорій — чиста виручка, маржа та повернення](Tableau/2.3_Kategorienperfomance.jpg)

### Ключовий результат

- **Electronics** — ~$1.99M чистої виручки, але лише **12% маржі** та **15.97% повернень**.
- **Beauty** — ~$159K виручки, **55% маржі**, 9.97% повернень.
- **Clothing** — висока маржа 45%, але найвищий рівень повернень — 16%.

### Бізнес-висновок

Категорії не можна оцінювати лише за виручкою.

- **Electronics** — працювати над маржею, асортиментом і причинами повернень.
- **Beauty** — тестувати контрольоване масштабування.
- **Clothing** — окремо дослідити причини високих повернень.

---

## 2.4. Регіональна динаміка 2022–2024

### Бізнес-питання

Які регіони є найбільшими за виручкою і де знаходиться потенціал для подальшого масштабування ShopSphere?

### SQL-запит

```sql
SELECT
    c.region,
    o.order_year,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(o.net_amount), 2) AS total_net_revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY
    c.region,
    o.order_year
ORDER BY
    c.region,
    o.order_year;
```

### SQL-запит та результат у SQLiteOnline

![SQL-запит — регіональна динаміка](SQL/2.4%20Regionen%20im%20Wandel.jpg)

### Візуалізація Tableau

![Регіональна динаміка 2022–2024](Tableau/2.4_Regionen%20im%20Wandel.jpg)

### Ключовий результат

У 2024 році:

- **North America** — 2,632 замовлення, ~$718.7K чистої виручки;
- **Southeast Asia** — 2,029 замовлень, ~$613.9K;
- **Europe** — ~$545.6K.

Southeast Asia демонструє дуже сильну динаміку, але частково це пояснюється низькою базою 2022 року — близько $12.7K.

### Бізнес-висновок

**North America** — поточний лідер за масштабом.

**Southeast Asia** — один із найперспективніших регіонів для контрольованого масштабування.

Рекомендується збільшувати інвестиції поступово, контролюючи ROI, LTV, абсолютну виручку та рівень повернень.

---

## 2.5. Pareto-аналіз клієнтів

### Бізнес-питання

Наскільки виручка ShopSphere концентрується серед найбільш цінних клієнтів і чи виконується класичне правило 80/20?

### SQL-запит

```sql
WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(net_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
),

ranked AS (
    SELECT
        customer_id,
        total_spent,

        ROW_NUMBER() OVER (
            ORDER BY total_spent DESC
        ) AS customer_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(total_spent) OVER (
            ORDER BY total_spent DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_spent,

        SUM(total_spent) OVER () AS grand_total_spent

    FROM customer_totals
)

SELECT
    customer_rank,

    ROUND(
        customer_rank * 100.0 / total_customers,
        2
    ) AS pct_of_customers,

    ROUND(total_spent, 2) AS total_spent,

    ROUND(
        cumulative_spent * 100.0 / grand_total_spent,
        2
    ) AS cumulative_pct_of_revenue

FROM ranked
ORDER BY customer_rank;
```

### SQL-запит та результат у SQLiteOnline

![SQL-запит — Pareto-аналіз клієнтів](SQL/2.5_pareto_customers.jpg)

SQL агрегує виручку на рівні клієнта, ранжує клієнтів за `total_spent` і розраховує накопичену частку виручки.

У Tableau клієнтів об'єднано у групи по 5%.

### Візуалізація Tableau

![Pareto-аналіз клієнтів](Tableau/2.5_Pareto-Verteilung%20der%20Kunden.jpg)

### Ключовий результат

- загалом **3,000 клієнтів**;
- Top-5% = **150 клієнтів**;
- вони генерують близько **$1.22M**;
- це **35.1% загальної виручки**;
- класичне правило 80/20 **не підтверджується**.

### Бізнес-висновок

Top-5% клієнтів потребують окремої retention-стратегії.

Одночасно варто розвивати сегмент 5–20%, щоб переводити частину клієнтів у High-Value групу та зменшувати концентраційний ризик.

---

## 2.6. Cross-Device поведінка та майбутня цінність клієнта

### Бізнес-питання

Чи є використання різних пристроїв під час перших двох покупок сигналом вищої майбутньої цінності клієнта?

Клієнти поділені на:

- **Same-Device** — перша і друга покупки зроблені з одного типу пристрою;
- **Cross-Device** — покупки зроблені з різних пристроїв.

Щоб уникнути bias через різну тривалість спостереження, використано однакове **90-денне вікно після другої покупки**.

До фінального аналізу включено клієнтів, друга покупка яких відбулася не пізніше `2024-10-02`.

### SQL-запит

```sql
WITH ranked_orders AS (

    SELECT
        customer_id,
        order_id,
        order_date,
        device,
        net_amount,
        is_returned,

        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS order_number

    FROM orders

    WHERE customer_id IS NOT NULL
      AND device IS NOT NULL
      AND TRIM(device) <> ''
),

customer_journey AS (

    SELECT
        customer_id,

        MAX(
            CASE
                WHEN order_number = 1 THEN device
            END
        ) AS first_device,

        MAX(
            CASE
                WHEN order_number = 2 THEN device
            END
        ) AS second_device,

        MAX(
            CASE
                WHEN order_number = 2 THEN order_date
            END
        ) AS second_order_date

    FROM ranked_orders
    GROUP BY customer_id
    HAVING COUNT(*) >= 2
),

eligible_customers AS (

    SELECT
        customer_id,
        second_order_date,

        CASE
            WHEN first_device = second_device
                THEN 'Same-Device'
            ELSE 'Cross-Device'
        END AS journey_segment

    FROM customer_journey

    WHERE second_order_date <= '2024-10-02'
),

customer_90d AS (

    SELECT
        e.customer_id,
        e.journey_segment,

        COUNT(r.order_id) AS future_orders_90d,

        COALESCE(
            SUM(r.net_amount),
            0
        ) AS future_revenue_90d,

        COALESCE(
            SUM(r.is_returned),
            0
        ) AS returned_orders_90d,

        CASE
            WHEN COUNT(r.order_id) > 0
                THEN 1
            ELSE 0
        END AS third_purchase_within_90d

    FROM eligible_customers AS e

    LEFT JOIN ranked_orders AS r
        ON e.customer_id = r.customer_id
        AND r.order_number >= 3
        AND (
            julianday(r.order_date)
            - julianday(e.second_order_date)
        ) BETWEEN 0 AND 90

    GROUP BY
        e.customer_id,
        e.journey_segment
)

SELECT
    journey_segment,

    COUNT(*) AS eligible_customers,

    SUM(third_purchase_within_90d)
        AS customers_with_third_purchase_90d,

    ROUND(
        100.0 * SUM(third_purchase_within_90d)
        / COUNT(*),
        2
    ) AS third_purchase_rate_pct,

    ROUND(
        AVG(future_orders_90d),
        2
    ) AS avg_future_orders_90d,

    ROUND(
        AVG(future_revenue_90d),
        2
    ) AS avg_future_revenue_90d,

    ROUND(
        CASE
            WHEN SUM(future_orders_90d) > 0
            THEN
                1.0 * SUM(future_revenue_90d)
                / SUM(future_orders_90d)
        END,
        2
    ) AS avg_future_order_value_90d,

    ROUND(
        CASE
            WHEN SUM(future_orders_90d) > 0
            THEN
                100.0 * SUM(returned_orders_90d)
                / SUM(future_orders_90d)
        END,
        2
    ) AS future_return_rate_pct

FROM customer_90d

GROUP BY journey_segment

ORDER BY avg_future_revenue_90d DESC;
```

### SQL-запит та результат у SQLiteOnline

![SQL-запит — Cross-Device поведінка та майбутня цінність клієнта](SQL/2.6_cross_device_customer_value.jpg)

### Результат

| Показник | Same-Device | Cross-Device |
|---|---:|---:|
| Eligible customers | 787 | 939 |
| Third purchase rate | 45.11% | 45.05% |
| Avg future orders, 90D | 0.90 | 0.86 |
| Avg future revenue, 90D | $285.57 | $266.55 |
| Avg future order value | $315.65 | $309.77 |
| Future return rate | 10.53% | 11.01% |

### Візуалізація Tableau

![Cross-Device customer value](Tableau/2.6_Cross-Device%20Kundenwert.jpg)

### Ключовий результат

Cross-Device клієнти **не показали очевидної переваги**:

- third purchase rate майже однаковий — 45.11% vs 45.05%;
- 90-day revenue — $285.57 Same-Device vs $266.55 Cross-Device;
- повернення також дуже схожі.

Статистичний тест для цієї різниці не проводився, тому її не можна трактувати як доведений причинний ефект.

### Бізнес-висновок

Cross-Device поведінка є поширеною, але не повинна самостійно використовуватися як ознака High-Value клієнта.

Її краще поєднувати з recency, frequency, monetary value, acquisition channel та LTV.

Водночас бізнесу важливо забезпечити безшовний cross-device customer experience.

---

# Блок 3. Фінальні Tableau Dashboard

Фінальні Dashboard побудовані за логікою:

**Monitor → Diagnose → Decide**

**побачити результат → зрозуміти драйвери → прийняти рішення**

| Dashboard | Основне питання |
|---|---|
| CEO Dashboard | Що відбувається з бізнесом? |
| Marketing & LTV | Де створюється маркетингова та клієнтська цінність? |
| A/B Test Checkout | Яке продуктове рішення потрібно прийняти? |

---

## 3.1. CEO Dashboard

*Leistung des globalen Marktplatzes — результати глобального маркетплейсу*

![ShopSphere CEO Dashboard](Tableau/CEO-Dashboard-Endfassung.jpg)

### Основні KPI

| KPI | Значення | Значення для бізнесу |
|---|---:|---|
| Bestellungen — замовлення | 12,274 | масштаб продажів |
| Nettoumsatz — чиста виручка | $3.47M | фінансовий результат |
| Bestellwert — середній чек | $283 | цінність одного замовлення |
| Retourenquote — повернення | 9.77% | якість продажів |

### Що CEO має побачити

1. **ShopSphere швидко зростає**, а листопад–грудень є ключовим сезонним періодом.
2. **North America** — найбільший ринок; **Southeast Asia** — сильний кандидат на масштабування.
3. **Electronics** домінує за виручкою, але має низьку маржу та високі повернення; **Beauty** має найвищу маржинальність.
4. Top-5% клієнтів генерують **35.1% виручки**.

Фільтри **Jahr — рік** і **Region — регіон** дозволяють деталізувати KPI та графіки.

---

## 3.2. Marketing & Customer LTV Dashboard

*Marketingkanäle: ROI vs. Kunden-LTV — маркетингові канали: ROI проти LTV*

![Marketing ROI and Customer LTV Dashboard](Tableau/CEO-Dashboard-Endfassung_2.jpg)

Dashboard поєднує:

- **короткострокову ефективність — ROI**;
- **довгострокову цінність — Customer LTV**.

### Ключові сигнали

- **Organic — ROI Leader — лідер за ROI:** 8.02.
- **Email:** ROI 6.50.
- **Influencer & Referral — LTV Leader — лідери за LTV.**
- **Paid Search — Optimierungsbedarf — потребує оптимізації:** 45.95% бюджету, ROI 1.33 і слабкий median LTV.

### Customer LTV

- Influencer — AVG ~$1.99K, median ~$1.20K;
- Referral — AVG ~$1.79K, median ~$1.12K;
- Paid Search — AVG ~$0.65K, median ~$0.28K.

Heatmap Top-5% показує, **з яких комбінацій `region × acquisition channel` приходить найбільше High-Value виручки**.

### Бізнес-висновок

Маркетинг не варто оцінювати лише за одним KPI.

Organic та Email сильні за ROI, Influencer та Referral — за LTV, а Paid Search — головний кандидат на контрольовану оптимізацію бюджету.

---

## 3.3. A/B Test Checkout Dashboard

*Ergebnis und Rollout — результат і рішення щодо rollout*

![A/B Test Checkout Dashboard](Tableau/CEO-Dashboard-Endfassung_3.jpg)

### Основні результати

| Сегмент | Різниця B − A | Lift |
|---|---:|---:|
| Gesamt — усі клієнти | +$5.54 | +1.97% |
| Neukunden — нові клієнти | +$39.41 | +17.64% |
| Wiederkehrende Kunden — повторні клієнти | +$4.01 | +1.38% |

Variant B має вищий середній Bestellwert у всіх сегментах.

Однак:

- усі 95% confidence intervals перетинають 0;
- усі p-values > 0.05.

Отже, статистично підтвердженої переваги Variant B немає.

### Rollout Decision

**Kein voller Rollout — не робити повний rollout.**

Рекомендація — продовжити тест серед **Neukunden — нових клієнтів**, де observed uplift найбільший (+17.64%), і накопичити більшу вибірку.

---

## 3.4. Основні управлінські висновки

1. **ShopSphere активно зростає**, але має виражену сезонність.
2. **North America** — поточний лідер; **Southeast Asia** — сильний growth opportunity.
3. Висока виручка не гарантує високої економічної якості: **Electronics** потребує оптимізації, **Beauty** — тестового масштабування.
4. Top-5% клієнтів створюють **35.1% виручки** і потребують retention-стратегії.
5. Marketing mix можна покращити: **Paid Search** отримує найбільший бюджет при найнижчому ROI.
6. Variant B checkout має позитивний сигнал, але доказів для повного rollout поки недостатньо.

---

## 3.5. Рекомендації для бізнесу

1. Підготувати inventory, logistics і customer support до сезонних піків наприкінці року.
2. Зберігати сильні позиції в North America та контрольовано тестувати масштабування Southeast Asia.
3. Працювати над margin і returns Electronics та тестувати розвиток Beauty.
4. Створити retention-стратегію для Top-5% та розвивати клієнтів сегмента 5–20%.
5. Поетапно оптимізувати marketing mix, контролюючи marginal ROI, CAC і LTV.
6. Не робити повний rollout Variant B; продовжити тест серед нових клієнтів.




































