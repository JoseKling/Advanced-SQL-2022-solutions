-- Exercise 1
SELECT p.a, p.b * 2, p.c, p.d, p.e, p.f
-- SELECT pg_typeof(p.a), pg_typeof(p.b * 2), pg_typeof(p.c), pg_typeof(p.d), pg_typeof(p.e), pg_typeof(p.f)
FROM (VALUES (1,'2'::money,4 ,41+1::real,1::real,NULL),
(2,'5.72' ,1.32,2 ,2 ,NULL),
(3,'2'::money,5.77,3 ,3 ,NULL)) AS p(a,b,c,d,e,f)
WHERE p.c < 5.5;

CREATE TABLE p (
    a INT,
    b MONEY,
    c NUMERIC,
    d DOUBLE PRECISION,
    e REAL,
    f TEXT
);

INSERT INTO p VALUES
    (1,'2',4 ,41+1,1,NULL),
    (2,'5.72' ,1.32,2 ,2 ,NULL),
    (3,'2',5.77,3 ,3 ,NULL)
;

SELECT p.a, p.b * 2, p.c, p.d, p.e, p.f
-- SELECT pg_typeof(p.a), pg_typeof(p.b * 2), pg_typeof(p.c), pg_typeof(p.d), pg_typeof(p.e), pg_typeof(p.f)
FROM p AS p
WHERE p.c < 5.5;

DROP TABLE p;

-- Exercise 2
CREATE TABLE allcards_json (
    data jsonb
);

\copy allcards_json FROM './assignment04/AllCards.json';
-- \copy allcards_json FROM '/home/jkling/projects/AdvSQL/assignment04/AllCards.json';

CREATE TABLE mtj (
    name text PRIMARY KEY,
    mana_cost text,
    cmc numeric,
    type text,
    text text,
    power text,
    toughness text
);

-- 2.a
WITH entries AS (
    SELECT
        trim(cards.key)                       AS name,
        trim(cards.value->>'manaCost')        AS mana_cost,
        trim((cards.value->>'cmc'))::numeric  AS cmc,
        trim(cards.value->>'type')            AS type,
        trim(cards.value->>'text')            AS "text",
        trim(cards.value->>'power')           AS power,
        trim(cards.value->>'toughness')       AS toughness
    FROM allcards_json,
         jsonb_each(data) AS cards
)
INSERT INTO mtj SELECT * FROM entries;

-- 2.b
SELECT "name"
FROM mtj AS m
WHERE (
    m.power NOT LIKE '%\*%' AND
    m.toughness NOT LIKE '%\*%' AND
    m.cmc IS NOT NULL
    ) AND (
    CAST(m.toughness AS float) > 14 OR
    CAST(m.toughness AS float) > 14 OR
    CAST(m.toughness AS float) > CAST(m.power AS float)
    )
ORDER BY cmc DESC
LIMIT 5;

-- 2.c
SELECT count(*)
FROM mtj as m
WHERE m.mana_cost ~ '^(\{U\}){1,3}$';
-- WHERE m.mana_cost = ANY(ARRAY['{U}', '{U}{U}', '{U}{U}{U}']);

-- 2.d
SELECT array_to_json(array_agg(m.name)) AS json_array
FROM mtj AS m
WHERE m.cmc < 3 AND m.text LIKE '%Recover%';

SELECT array_to_json(array_agg(jb.key)) AS json_array
FROM allcards_json AS a,
     jsonb_each(a.data) as jb
WHERE (jb.value->>'cmc')::float < 3 AND
       jb.value->>'text' LIKE '%Recover%';

DROP TABLE mtj;
DROP TABLE allcards_json;

-- Exercise 3
\i ./assignment04/earthquakes.sql

-- 3.a
WITH depths AS (
    SELECT e.title AS title, (e.quake->'geometry'->'coordinates'->2)::float AS depth
    FROM earthquakes as e
)
SELECT d.title, d.depth
FROM depths AS d:
WHERE d.depth = (SELECT max(depth) FROM depths) OR 
      d.depth = (SELECT min(depth) FROM depths); 

-- 3.b
WITH mags AS (
    SELECT
        e.title AS title,
        (e.quake->'properties'->'mag')::float AS mag, 
        to_timestamp(((e.quake->'properties'->'time')::bigint) / 1000)::date AS "date" 
    FROM earthquakes AS e
), max AS (
    SELECT m.date, max(m.mag) AS max
    FROM mags AS m
    GROUP BY m.date 
)
SELECT m.date, m.title
FROM mags AS m
INNER JOIN max ON (max.date, max.max)=(m.date, m.mag);

-- 3.c
\set sand_lat 48.534542
\set sand_lon 9.07129

WITH positions AS (
    SELECT
        e.title AS title,
        (e.quake->'geometry'->'coordinates'->0)::float AS lon,
        (e.quake->'geometry'->'coordinates'->1)::float AS lat
    FROM earthquakes as e
), distances AS (
    SELECT p.title, haversine(p.lat, p.lon, :sand_lat, :sand_lon) AS distance
    FROM positions AS p
)
SELECT d.title
FROM distances as d
WHERE d.distance = (SELECT min(distance) FROM distances);
