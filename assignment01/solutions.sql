-- Exercise 2
CREATE TABLE r (
    a INT,
    b INT
);

INSERT INTO r VALUES
(1, 1),
(1, 3),
(2, 1),
(2, 2);

SELECT r.a, count(*) AS c
FROM r AS r
WHERE r.b <> 3
GROUP BY r.a;

SELECT r.a, count(*) AS c
FROM r AS r
GROUP BY r.a
HAVING EVERY(r.b <> 3);

DROP TABLE r;

-- Exercise 3
CREATE TABLE production (
    item char(20) NOT NULL,
    step int NOT NULL,
    completion timestamp, -- NULL means incomplete
    PRIMARY KEY (item, step)
);

INSERT INTO production VALUES
('TIE', 1, '1977/03/02 04:12'),
('TIE', 2, '1977/12/29 05:55'),
('AT-AT', 1, '1978/01/03 14:12'),
('AT-AT', 2, NULL),
('DSII', 1, NULL),
('DSII', 2, '1979/05/26 20:05'),
('DSII', 3, '1979/04/04 17:12');

SELECT "item"
FROM production AS p
GROUP BY p.item
HAVING EVERY(p.completion IS NOT NULL);

DROP TABLE production;

-- Exercise 3
CREATE TABLE A (
 row int,
 col int,
 val int,
 PRIMARY KEY(row, col));

CREATE TABLE B (LIKE A);

INSERT INTO A (row,col,val)
VALUES (1,1,1), (1,2,2),
(2,1,3), (2,2,4);

INSERT INTO B (row,col,val)
VALUES (1,1,1), (1,2,2), (1,3,1),
(2,1,2), (2,2,1), (2,3,2);

-- 3.a
WITH prods AS (
    SELECT a.row AS row, b.col AS col, a.val * b.val AS prod
    FROM A AS a
    INNER JOIN B AS b
    ON a.col = b.row -- Exclude missing entries from computations
)
SELECT p.row AS row, p.col AS col, sum(p.prod) AS val
FROM prods AS p
GROUP BY p.row, p.col
ORDER BY p.row, p.col;

-- 3.b
DROP TABLE A;
DROP TABLE B;

CREATE TABLE A (
 row int,
 col int,
 val int,
 PRIMARY KEY(row, col));

CREATE TABLE B (LIKE A);

INSERT INTO A (row,col,val)
VALUES (1,1,1), (1,2,3),
(2,3,7);

INSERT INTO B (row,col,val)
VALUES (1,1,4), (1,3,8 ),
(2,1,1), (2,2,1), (2,3,10),
(3,1,3), (3,2,6);

-- This works for sparse matrices, because whenever some entry
-- is missing, the first 'WHERE' clause excludes it from the
-- computation, so does not participate in the sum.
WITH prods AS (
    SELECT a.row AS row, b.col AS col, a.val * b.val AS prod
    FROM A AS a
    INNER JOIN B AS b
    ON a.col = b.row -- Exclude missing entries from computations
)
SELECT p.row AS row, p.col AS col, sum(p.prod) AS val
FROM prods AS p
GROUP BY p.row, p.col
ORDER BY p.row, p.col;

DROP TABLE A;
DROP TABLE B;