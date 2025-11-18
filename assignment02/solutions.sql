-- Exercise 1
-- 1.a
CREATE TABLE measurements (
    id SERIAL PRIMARY KEY,
    t NUMERIC,
    m NUMERIC
);

INSERT INTO measurements (t, m) VALUES
(1.0, 1.0), 
(1.0, 3.0),
(1.0, 5.0),
(1.0, 5.0),
(2.5, 0.8),
(2.5, 2.0),
(4.0, 0.5),
(5.5, 3.0),
(8.0, 2.0),
(8.0, 6.0),
(8.0, 8.0),
(10.5, 1.0),
(10.5, 3.0),
(10.5, 8.0);

-- 1.b
SELECT max(m) AS max
FROM measurements;

-- 1.c
SELECT t, avg(m) AS avg
FROM measurements
GROUP BY t;

-- 1.d
SELECT
    floor(t / 5) * 5       AS start,
    (floor(t / 5) * 5) + 5 AS end,
    avg(m)                 AS avg
FROM measurements
GROUP BY floor(t / 5)
ORDER BY start;

-- 1.e
SELECT DISTINCT t, m AS max
FROM measurements
WHERE m = (
    SELECT max(m)
    FROM measurements
);

DROP TABLE measurements;
-- Exercise 2

CREATE TABLE tree (
level_a char(2),
level_b char(2),
level_c char(2),
level_d char(2),
leaf_value int
);

INSERT INTO tree(level_a, level_b, level_c, level_d, leaf_value)
VALUES ('A1', 'B1', 'C1', 'D1', 1),
('A1', 'B1', 'C1', 'D2', 2),
('A1', 'B1', 'C2', 'D3', 4),
('A1', 'B1', 'C2', 'D4', 8),
('A1', 'B2', 'C3', 'D5', 16),
('A1', 'B2', 'C3', 'D6', 32),
('A1', 'B2', 'C4', NULL, 64);

-- 2.a
SELECT any_value(t.level_a), t.level_b, t.level_c, t.level_d, sum(t.leaf_value)
FROM tree AS t
GROUP BY ROLLUP (t.level_b, t.level_c, t.level_d)
ORDER BY t.level_d, t.level_c, t.level_b;

-- 2.b
SELECT DISTINCT
    any_value(t.level_a),
    t.level_b,
    t.level_c,
    t.level_d,
    CASE
        WHEN count(t.leaf_value) = 1 
        THEN 0
        ELSE count(t.leaf_value)
    END AS n_leaves
FROM tree AS t
GROUP BY ROLLUP (t.level_b, t.level_c, t.level_d)
ORDER BY t.level_d, t.level_c, t.level_b;

-- 2.c
SELECT DISTINCT t.level_a, t.level_b, t.level_c, t.level_d, max(t.leaf_value)
FROM tree AS t
GROUP BY t.level_a, ROLLUP (t.level_b, t.level_c, t.level_d)
ORDER BY t.level_d, t.level_c, t.level_b, t.level_a;

DROP TABLE tree;