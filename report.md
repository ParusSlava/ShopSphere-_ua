# ShopSphere — аналіз глобального маркетплейсу

## Executive Summary

ShopSphere — аналітичний проєкт глобального маркетплейсу за 2022–2024 роки.

Мета проєкту — не просто описати продажі, а відповісти на ключові управлінські питання:

- як і за рахунок чого росте бізнес;
- наскільки ефективно використовується маркетинговий бюджет;
- які канали приводять найбільш цінних клієнтів;
- які товарні категорії справді економічно привабливі;
- які регіони мають найбільший потенціал;
- наскільки виручка залежить від невеликої групи High-Value клієнтів;
- чи допомагають великі знижки формувати повторні покупки;
- чи спрацював A/B-експеримент нового checkout.

За результатами аналізу були створені три управлінські Tableau Dashboard:

1. **CEO Dashboard** — загальна картина бізнесу.
2. **Marketing & Customer LTV Dashboard** — ефективність маркетингових каналів і цінність клієнтів.
3. **A/B Test Checkout Dashboard** — статистична оцінка продуктового експерименту.

Основний принцип проєкту:

**дані → SQL-аналіз → візуалізація → інтерпретація → бізнес-рішення.**

## Business Context

CEO ShopSphere хоче зрозуміти не лише те, чи зростає компанія, а й **якість цього зростання**.

Основні бізнес-питання:

- Куди спрямовуються маркетингові гроші і чи окупаються вони?
- Хто є найціннішими клієнтами?
- Які категорії генерують якісну виручку, а які лише створюють великий оборот?
- Які регіони можуть стати наступними драйверами зростання?
- Наскільки бізнес залежить від High-Value клієнтів?
- Чи підтримують знижки довгострокову активність клієнтів?
- Чи варто масштабувати новий дизайн checkout?

Тому аналіз був побудований не навколо окремих графіків, а навколо конкретних бізнес-рішень.

## Data & Methodology

Для аналізу використовувалися п'ять основних таблиць:

### `customers`
Дані про клієнтів:
- customer_id;
- region;
- country;
- age;
- gender;
- acquisition_channel;
- signup_date.

### `orders`
Дані про замовлення:
- order_id;
- customer_id;
- order_date;
- device;
- channel;
- discount_pct;
- gross_amount;
- discount_amount;
- net_amount;
- free_shipping;
- ab_variant;
- is_returned.

### `order_items`
Деталізація товарів усередині замовлення.

### `products`
Дані про товари та категорії, включно з ціною, собівартістю та маржею.

### `marketing`
Дані маркетингових кампаній:
- channel;
- budget;
- impressions;
- clicks;
- conversions;
- attributed_revenue.


  ## Analytical Workflow

Проєкт був реалізований у декілька етапів:

### 1. SQL
SQL використовувався для:
- перевірки та підготовки даних;
- JOIN таблиць;
- агрегації;
- розрахунку KPI;
- сегментації клієнтів;
- ranking та window functions;
- Pareto-аналізу;
- підготовки датасетів для Tableau;
- підготовки вибірки A/B-експерименту.

### 2. Python / Google Colab
Python використовувався для статистичної перевірки A/B-експерименту:
- descriptive statistics;
- Welch t-test;
- 95% confidence intervals;
- p-values.

### 3. Tableau
Tableau використовувався для:
- exploratory visualizations;
- KPI;
- порівняння сегментів;
- інтерактивних фільтрів;
- створення трьох фінальних управлінських Dashboard.

### Analytical Pipeline

**Raw Data → SQL → Analytical Dataset → Python Statistics → Tableau → Business Decision**

# Аналіз 2.1. Сезонність та динаміка виручки
# Analyse 2.1. Saisonalität und Umsatzentwicklung

## Business Question
## Бізнес-питання

Wie entwickelt sich der Nettoumsatz von ShopSphere im Zeitverlauf und gibt es wiederkehrende saisonale Umsatzspitzen?

Як змінюється чиста виручка ShopSphere у часі та чи існують повторювані сезонні піки продажів?

---

## Verwendete Daten
## Використані дані

Для аналізу використовувалась таблиця `orders`.

Основні поля:

- `order_id` — унікальний номер замовлення;
- `order_year` — рік замовлення;
- `order_month` — місяць замовлення;
- `net_amount` — чиста сума замовлення після знижки.

Оскільки метою було дослідити динаміку продажів у часі, окремі замовлення були агреговані до рівня місяця.

---

## SQL-Abfrage
## SQL-запит

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

## Tableau-Visualisierung
## Візуалізація Tableau

![Umsatzentwicklung 2022–2024](Tableau/2.1_Sansonalität.jpg)

На графіку:

- X-Achse — місяці;
- Y-Achse — чиста виручка;
- темна лінія — загальна динаміка виручки;
- фіолетові ділянки — періоди сезонних піків;
- підписи показують грудневі максимуми 2022, 2023 та 2024 років.











