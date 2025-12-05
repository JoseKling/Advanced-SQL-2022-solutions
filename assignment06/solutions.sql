-- Exercise 1
CREATE TABLE arrays (
id int GENERATED ALWAYS AS IDENTITY,
arr int[] CHECK (cardinality(arr) > 0)
);

INSERT INTO arrays(arr) VALUES
(ARRAY[1,2,3,5,6]),
(ARRAY[4,3]),
(ARRAY[7,6,9]),
(ARRAY[2,2]);

CREATE OR REPLACE
FUNCTION is_sorted(arr NUMERIC ARRAY)
RETURNS BOOLEAN
AS $$
    WITH arr_tb AS (
        SELECT a.idx AS idx, a.val AS val
        FROM unnest(arr) WITH ORDINALITY AS a(val, idx)
    )
    SELECT bool_and(tail.val - head.val >= 0)
    FROM (SELECT * FROM arr_tb WHERE idx > 1) AS tail
    JOIN (SELECT * FROM arr_tb WHERE idx < cardinality(arr)) AS head
        ON tail.idx - 1 = head.idx
$$ LANGUAGE SQL IMMUTABLE;

SELECT *
FROM arrays
WHERE is_sorted(arrays.arr)
ORDER BY id;

-- Exercise 2
\set N 43

WITH lights_start AS (
    SELECT seq AS n, false AS "ON?"
    FROM generate_series(1, :N) AS seq
), lights_end AS (
    SELECT 
        l.n AS light, count(p) filter (where cast(l.n % p AS int) = 0) % 2 AS "ON?"
    FROM
        lights_start AS l,
        LATERAL generate_series(1, l.n) AS p
    GROUP BY l.n
)
SELECT sum("ON?")
FROM lights_end;

-- Exercise 3
CREATE DOMAIN result AS numeric(3,1);

CREATE TABLE analysis (
dataset char(1) NOT NULL,
x numeric NOT NULL,
y numeric NOT NULL
);

 \copy analysis FROM 'assignment06/data.csv' WITH (FORMAT csv, HEADER TRUE);

 -- 3.a
 SELECT
    a.dataset AS dataset,
    cast(avg(a.x) AS result) AS x_mean, 
    cast(avg(a.y) AS result)AS y_mean, 
    cast(stddev(a.y) AS result)AS x_stddev, 
    cast(stddev(a.y) AS result) AS y_stdddev, 
    cast(corr(a.x, a.y) AS result) AS correlation
FROM analysis AS a
GROUP BY a.dataset
ORDER BY a.dataset; 

-- 3.b
-- pdf images in this folder

-- Exercise 4
-- 4.a
CREATE OR REPLACE FUNCTION val(digits int[])
RETURNS int
AS $$
    SELECT sum((10 ^ (cardinality(digits) - d.idx)) *  d.val)
    FROM unnest(digits) WITH ORDINALITY AS d(val, idx)
$$ LANGUAGE SQL IMMUTABLE;

-- 4.b
WITH possibilities AS (
    SELECT 9 AS S, E AS E, E + 1 AS N, D AS D, 1 AS M, 0 AS O, R AS R, Y AS Y
    FROM
        generate_series(1, 8) AS E,
        generate_series(1, 8) AS D,
        generate_series(1, 8) AS R,
        generate_series(1, 8) AS Y

)
SELECT *
FROM possibilities AS p
WHERE val(ARRAY[p.S, p.E, p.N, p.D]) +
      val(ARRAY[p.M, p.O, p.R, p.E]) =
        val(ARRAY[p.M, p.O, p.N, p.E, p.Y]) AND
    cardinality(ARRAY[p.S, p.E, p.N, p.D, p.M, p.O, p.R, p.Y]) = (
        SELECT count(DISTINCT rows)
        FROM unnest(ARRAY[p.S, p.E, p.N, p.D, p.M, p.O, p.R, p.Y]) AS rows
    );