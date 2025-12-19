-- Exercise 1
\i ./assignment08/tour.sql

-- 1.a (home is the first waypoint)
SELECT 
    t.id AS id,
    distance(LAST_VALUE(t.waypoint) OVER win, FIRST_VALUE(t.waypoint) OVER win) AS "distance"
FROM tour AS t
WINDOW win AS (ORDER BY t.id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW);

-- 1.b
/*
How to calculate the distance between two consecutive waypoints
w1, w2 accounting for elevation. c1, c2 are the coordinates and
e1, e2 the elevations.

d(w1, w2) = sqrt(distance(c1, c2)^2 + (e1 - e2)^2)
*/
SELECT 
    t.id AS id,
    SQRT(distance(LAST_VALUE(t.waypoint) OVER win,
                  FIRST_VALUE(t.waypoint) OVER win)^2
        +
         (LAST_VALUE(t.elevation) OVER win -
          FIRST_VALUE(t.elevation) OVER win)^2
    ) AS "cycled distance"
FROM tour AS t
WINDOW win AS (ORDER BY t.id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW);

-- 1.c
SELECT 
    t.id AS id,
    CASE (LAG(t.waypoint, 1) OVER () - LEAD(t.waypoint, 1) OVER ())
    WHEN 0 THEN 0
    ELSE (LAG(t.elevation, 1) OVER () - LEAD(t.elevation, 1) OVER ())
            * 100 /
         distance(LAG(t.waypoint, 1) OVER (),
                  LEAD(t.waypoint, 1) OVER ())
    END AS "slope (%)"
FROM tour AS t;

DROP TABLE tour;

-- Exercise 2
CREATE TABLE work (
emp_id int,
login date
);

INSERT INTO work(emp_id, login) VALUES
(2,'2016-04-12'), (4,'2016-04-17'),
(2,'2016-04-11'), (4,'2016-04-06'),
(4,'2016-04-07'), (2,'2016-04-06')
(2,'2016-04-07'), (5,'2016-04-07'),
(5,'2016-04-08'), (2,'2016-04-10')
(2,'2016-04-06'), (5,'2016-04-09');

WITH distinct_logins AS (
    SELECT DISTINCT * FROM work
), groups AS (
    SELECT
        w.emp_id AS emp_id,
        (CAST(w.login - FIRST_VALUE(w.login) OVER win AS int) + 1) - ROW_NUMBER() OVER win AS group
    FROM distinct_logins AS w
    WINDOW win AS (PARTITION BY w.emp_id
                ORDER BY w.login)
), streaks AS (
    SELECT DISTINCT
        g.emp_id AS emp_id,
        COUNT(*) AS streak
    FROM groups AS g
    GROUP BY g.emp_id, g.group
    ORDER BY g.emp_id
)
SELECT s.emp_id AS emp_id, MAX(s.streak) AS max_streak
FROM streaks AS s
GROUP BY s.emp_id
ORDER BY s.emp_id;

DROP TABLE work;

-- Exercise 3
CREATE TYPE coin AS ENUM('gold', 'silver');

CREATE TABLE coins (
id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
coin coin
);

INSERT INTO coins(coin)
SELECT CASE WHEN random() < 0.3
THEN 'gold'
ELSE 'silver'
END :: coin AS coin
FROM generate_series(1,100) AS _;

WITH GoldCoins AS (
    SELECT
        c.id AS id,
        SUM(CASE WHEN c.coin = 'gold' THEN 1 ELSE 0 END) OVER win AS golds
    FROM coins AS c 
    WINDOW win AS (ORDER BY c.id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
), newChest AS (
    SELECT
        g.id AS id,
        LAG(g.golds, 1) OVER win < g.golds AND g.golds % 3 = 0 AS next_chest 
    FROM GoldCoins AS g 
    WINDOW win AS (ORDER BY g.id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
), cumsum AS (
    SELECT SUM(CAST(n.next_chest AS int)) OVER win AS chest_id, n.id AS "cumsum"
    FROM newChest AS n
    WHERE n.next_chest
    WINDOW win AS (ORDER BY n.id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)
SELECT c.chest_id, c.cumsum - LAG(c.cumsum, 1, 0) OVER () AS "# of coins"
FROM cumsum AS c;

DROP TABLE coins;