
CREATE OR REPLACE FUNCTION offers(on_day date)
RETURNS TABLE (
    master_id integer,
    service_id integer,
    name text,
    category text,
    duration integer,
    original numeric,
    price numeric,
    discount integer
)
LANGUAGE sql STABLE AS $$
    -- получаем исходные цены мастеров
    WITH base AS (
        SELECT
            t.master_id,
            s.id AS service_id,
            s.name,
            s.category,
            s.duration,
            COALESCE(t.price, s.price) AS original
        FROM tariffs t
        JOIN services s ON s.id = t.service_id
        JOIN users u ON u.id = t.master_id
        WHERE u.active AND s.active
    ),

    -- находим максимальную подходящую скидку
    discounts AS (
        SELECT
            b.*,
            COALESCE((
                SELECT MAX(p.discount)
                FROM promotions p
                WHERE p.service_id = b.service_id
                  AND (p.master_id = b.master_id OR p.master_id IS NULL)
                  AND on_day BETWEEN p.begins AND p.ends
            ), 0) AS discount
        FROM base b
    )

    -- рассчитываем итоговую цену
    SELECT
        d.master_id,
        d.service_id,
        d.name,
        d.category,
        d.duration,
        d.original,
        ROUND(d.original * (100 - d.discount) / 100, 2) AS price,
        d.discount
    FROM discounts d;
$$;
