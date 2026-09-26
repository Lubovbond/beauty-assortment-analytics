-- ====================================================================
-- Агрегация транзакционных метрик и расчет операционных KPI бьюти-ритейла
-- ====================================================================

-- 1. Расчет общей выручки, объема продаж и процента выкупа по месяцам
SELECT 
    month_name AS "Месяц",
    -- Общая сумма заказов до выкупа
    SUM(price * quantity) AS total_ordered_value,
    -- Фактическая выручка (только за то, что реально выкупили в ПВЗ)
    SUM(CASE WHEN is_bought = 1 THEN price * quantity ELSE 0 END) AS actual_revenue,
    -- Объем продаж в штуках
    SUM(CASE WHEN is_bought = 1 THEN quantity ELSE 0 END) AS units_sold,
    -- Расчет процента выкупа (отношение выручки к заказанному объему)
    ROUND(
        (SUM(CASE WHEN is_bought = 1 THEN price * quantity ELSE 0 END) * 100.0) / 
         SUM(price * quantity), 2
    ) AS buyout_rate_percent
FROM 
    orders_cosmetics
GROUP BY 
    month_name
ORDER BY 
    "Месяц" DESC;


-- 2. Поиск брендов-аутсайдеров с критически низким уровнем выкупа (ниже целевых 95%)
SELECT 
    brand_name AS "Бренд",
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price * quantity) AS total_ordered_value,
    SUM(CASE WHEN is_bought = 1 THEN price * quantity ELSE 0 END) AS actual_revenue,
    -- Процент выкупа по конкретному бренду
    ROUND(
        (SUM(CASE WHEN is_bought = 1 THEN price * quantity ELSE 0 END) * 100.0) / 
         SUM(price * quantity), 2
    ) AS buyout_rate_percent
FROM 
    orders_cosmetics
GROUP BY 
    brand_name
HAVING 
    -- Фильтруем только те бренды, которые не выполняют финансовый KPI бизнеса
    (SUM(CASE WHEN is_bought = 1 THEN price * quantity ELSE 0 END) * 100.0) / SUM(price * quantity) < 95.0
ORDER BY 
    buyout_rate_percent ASC
LIMIT 10;
