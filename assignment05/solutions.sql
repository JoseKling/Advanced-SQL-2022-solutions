-- Exercise 1
CREATE TABLE s (
arr_id integer PRIMARY KEY,
arr text[]
);

INSERT INTO s VALUES
(1, ARRAY['a','b','c']),
(2, ARRAY['d','d']);

CREATE TABLE t (
arr_id integer,
idx integer,
val text,
PRIMARY KEY(arr_id, idx)
);

INSERT INTO t VALUES
(1,1,'a'),(1,2,'b'),(1,3,'c'),
(2,1,'d'),(2,2,'d');

-- 1.a
SELECT s.arr[1] AS val
FROM s AS s
WHERE s.arr_id = 1;

SELECT t.val AS val
FROM t AS t
where t.arr_id = 1 AND t.idx = 1;

-- 1.b
SELECT s.arr_id,
array_length(s.arr,1) AS len
FROM s AS s;

SELECT t.arr_id, count(t.idx) AS len
FROM t AS t
GROUP BY t.arr_id;

-- 1.c
SELECT s.arr_id, a AS val
FROM s AS s,
     unnest(s.arr) AS a;

SELECT t.arr_id, t.val
FROM t;

-- 1.d
SELECT s.arr_id,
       array_cat(s.arr,ARRAY['e','f'])
FROM s AS s;

CREATE TABLE arr (
idx SERIAL PRIMARY KEY,
val text
);

INSERT INTO arr VALUES
(1, 'e'), (2, 'f');

SELECT *
FROM (
SELECT arr_id, idx, val
FROM t

UNION ALL

SELECT
    m.arr_id AS arr_id,
    m.max_id + a.idx AS idx,
    a.val AS val
FROM
    arr AS a,
    (
        SELECT arr_id, max(idx) AS max_id
        FROM t
        GROUP BY arr_id
    ) AS m
)
ORDER BY arr_id, idx;

-- 1.e
TABLE s
UNION ALL
SELECT new.id AS arr_id,
s.arr||'g'::text AS arr
FROM s AS s, (
SELECT MAX(s.arr_id) + 1
FROM s AS s
) AS new(id)
WHERE s.arr_id = 1;

WITH max_ids AS (
    SELECT max(t.arr_id) AS max_arr,
           (SELECT max(idx) FROM t WHERE arr_id = 1) AS max_idx
    FROM t AS t
), new_arr AS (
    SELECT m.max_arr + 1 AS arr_id, t.idx AS idx, t.val AS val
    FROM max_ids AS m, t AS t
    WHERE t.arr_id = 1

    UNION ALL

    SELECT m.max_arr + 1, m.max_idx + 1, 'g'
    FROM max_ids AS m
)
SELECT * 
FROM (
TABLE new_arr

UNION ALL

TABLE t)
ORDER BY arr_id, idx;

DROP TABLE t;
DROP TABLE s;
-- Exercise 2
CREATE TABLE matrices (
matrix text[][] NOT NULL
);

INSERT INTO matrices VALUES
(array[['1','2','3'],
['4','5','6']]),
(array[['f','e','d'],
['c','b','a']]);

WITH matrices_id AS (
    SELECT row_number() OVER () AS id, matrix
    FROM matrices
), transpose_tb AS (
    SELECT m.id, c AS row, r AS col, m.matrix[r][c] AS val
    FROM matrices_id AS m
    CROSS JOIN generate_subscripts(m.matrix, 1) AS r
    CROSS JOIN generate_subscripts(m.matrix, 2) AS c
), rows_tb AS (
    SELECT t.id AS id, t.row AS row, array_agg(t.val) AS val
    FROM transpose_tb AS t
    GROUP BY t.id, t.row
    ORDER BY t.id, t.row
)
SELECT array_agg(r.val) AS matrix
FROM rows_tb AS r
GROUP BY r.id;

DROP TABLE matrices;

-- Exercise 3
CREATE TABLE trees (
tree int PRIMARY KEY,
parents int[],
labels numeric[]
);

INSERT INTO trees VALUES
(1, ARRAY[NULL,1,2,2,1,5],
ARRAY[3.3,1.4,5.0,1.3,1.6,1.5]),
(2, ARRAY[3,3,NULL,3,2],
ARRAY[0.4,0.4,0.2,0.1,7.0]);

WITH tree_tb AS (
    SELECT
        t.tree AS tree_id,
        p.node_id AS node_id,
        p.parent AS parent,
        t.labels[p.node_id] AS label
    FROM
        trees AS t,
        unnest(t.parents) WITH ORDINALITY AS p(parent, node_id)
), parent_sums AS (
    SELECT
        t.tree_id AS tree_id,
        t.parent AS node_id,
        sum(t.label) AS sum
    FROM tree_tb AS t
    WHERE t.parent IS NOT NULL
    GROUP BY t.tree_id, t.parent
)
SELECT
    t.tree_id AS tree,
    t.node_id AS node,
    COALESCE(p.sum, 0.0) AS sum
FROM tree_tb AS t
LEFT JOIN parent_sums AS p ON t.node_id = p.node_id AND t.tree_id = p.tree_id
ORDER BY tree, node;