DROP TABLE IF EXISTS raw;
CREATE TABLE raw (
  data jsonb
);

\copy raw FROM '/home/jkling/projects/AdvSQL/assignment04/earthquakes.json';

DROP TABLE IF EXISTS earthquakes;
CREATE TABLE earthquakes ( 
  title text, 
  quake jsonb 
);

INSERT INTO earthquakes(title,quake)
SELECT e['properties']['title'] :: text AS title, e :: jsonb AS quake
FROM   raw AS r, 
       LATERAL jsonb_path_query(r.data, '$.features[*]') AS e;

DROP TABLE IF EXISTS raw;

-- Distance between two positions on earth.
CREATE OR REPLACE FUNCTION haversine(lat_p1 float,
                                     lon_p1 float,
                                     lat_p2 float,
                                     lon_p2 float) RETURNS float AS $$
  SELECT 2 * 6371000 * asin(sqrt(sin(radians(lat_p2 - lat_p1) / 2) ^ 2 +
                                 cos(radians(lat_p1)) *
                                 cos(radians(lat_p2)) *
                                 sin(radians(lon_p2 - lon_p1) / 2) ^ 2)) AS dist;
$$ LANGUAGE SQL IMMUTABLE;