-- Exercise 1
-- 1.a
CREATE TABLE depths (
    "line" INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    depth INT
);
\copy depths(depth) FROM 'assignment07/exercise1.data';

-- 1.b
WITH descents AS (
    SELECT d.line, d.depth - LAG(d.depth, 1) OVER two_rows > 0 AS "increased?" 
    FROM depths as d
    WINDOW two_rows AS (ORDER BY "line" ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
)
SELECT count(d.line)
FROM descents AS d
WHERE d."increased?" AND d.line >= 2;

-- 1.c
WITH sums AS (
    SELECT d.line, SUM(d.depth) OVER three_rows AS "sum" 
    FROM depths as d
    WINDOW three_rows AS (ORDER BY "line" ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
), descents AS (
    SELECT s.line, s.sum - LAG(s.sum, 1) OVER two_rows > 0 AS "increased?" 
    FROM sums as s
    WINDOW two_rows AS (ORDER BY "line" ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
)
SELECT count(d.line)
FROM descents AS d
WHERE d."increased?" AND d.line >= 4;

DROP TABLE depths;

-- Exercise 2
CREATE TABLE seesaw (
pos int GENERATED ALWAYS AS IDENTITY,
weight int NOT NULL
);

INSERT INTO seesaw(weight) (
SELECT floor(random()*10) AS weight
FROM generate_series(1,100) AS _
);

WITH weightslr AS (
    SELECT s.pos AS pos,
        sum(s.weight) OVER (ORDER BY s.pos ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS left,
        sum(s.weight) OVER (ORDER BY s.pos ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS right
    FROM seesaw AS s
), diffs AS (
    SELECT w.pos AS pos, ABS(w.left - w.right) AS diff
    FROM weightslr AS w
)
SELECT d.pos AS pos, d.diff AS diff
FROM diffs AS d
WHERE d.diff = (SELECT MIN(diff) FROM diffs);

DROP TABLE seesaw;

-- Exercise 3
CREATE TABLE measurements (
ts timestamp PRIMARY KEY,
val numeric
);

INSERT INTO measurements VALUES 
('2019-12-04 07:34:59', NULL),
('2019-12-04 07:37:16', 42.0),
('2019-12-04 07:38:36', 4.1),
('2019-12-04 07:42:33', NULL),
('2019-12-04 07:55:06', NULL),
('2019-12-04 07:57:06', 12.3),
('2019-12-04 08:03:18', NULL),
('2019-12-04 08:15:44', 15.1),
('2019-12-04 08:22:21', 2.2),
('2019-12-04 08:37:31', NULL);

WITH notnulls AS (
    SELECT
        m.ts,
        m.val,
        sum(CAST(m.val IS NOT NULL AS INT)) OVER win AS group
    FROM measurements AS m
    WINDOW win AS (ORDER BY m.ts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
), imputed AS (
    SELECT 
        n.ts, 
        FIRST_VALUE(n.val) OVER win AS val
    FROM notnulls AS n
    WINDOW win AS (ORDER BY n.group GROUPS BETWEEN CURRENT ROW AND CURRENT ROW)
)
SELECT *
FROM imputed
WHERE val IS NOT NULL;

DROP TABLE measurements;