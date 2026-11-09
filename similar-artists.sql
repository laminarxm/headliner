-- =========================================================================
-- similar-artists.sql - "who is like whom" queries (Advanced SQL)
-- run order: after permissions.sql (it grants the view to the existing roles)
-- A. shared genres, with a size-adjusted score   (self-join + CTE + GROUP BY)
-- B. co-billing: who has played shows with whom  (self-join on the weak key)
-- C. degrees of separation                       (recursive CTE + window fn)
-- D. rank / next-show                            (window functions)
-- E. v_public_similar_artists                    (A as a view for everyone)
-- =========================================================================
USE showsdb;
 
-- A. Genre similarity. Jaccard score = shared genres / genres in either artist.
--    a.artist_name < b.artist_name lists each pair once.
WITH genre_counts AS (
    SELECT `artist_name`, COUNT(*) AS n FROM `ArtistGenre` GROUP BY `artist_name`
), shared AS (
    SELECT a.`artist_name` AS artist_a, b.`artist_name` AS artist_b, COUNT(*) AS shared_genres,
           GROUP_CONCAT(a.`genre` ORDER BY a.`genre` SEPARATOR ', ') AS genres
    FROM `ArtistGenre` a
    JOIN `ArtistGenre` b ON a.`genre` = b.`genre` AND a.`artist_name` < b.`artist_name`
    GROUP BY a.`artist_name`, b.`artist_name`
)
SELECT s.artist_a, s.artist_b, s.shared_genres, s.genres,
       ROUND(s.shared_genres / (ga.n + gb.n - s.shared_genres), 2) AS similarity
FROM shared s
JOIN genre_counts ga ON ga.`artist_name` = s.artist_a
JOIN genre_counts gb ON gb.`artist_name` = s.artist_b
ORDER BY similarity DESC, s.artist_a, s.artist_b;
 
-- B. Co-billing: pairs that have shared a show.
SELECT a.`artist_name` AS artist, b.`artist_name` AS played_with,
       COUNT(*) AS shows_together, MAX(a.`date_time`) AS most_recent
FROM `PlaysAt` a
JOIN `PlaysAt` b ON  b.`venue_name` = a.`venue_name`
                 AND b.`date_time`  = a.`date_time`
                 AND b.`artist_name` <> a.`artist_name`
GROUP BY a.`artist_name`, b.`artist_name`
ORDER BY a.`artist_name`, shows_together DESC, b.`artist_name`;
 
-- C. Degrees of separation through shared bills, starting from one artist
--    (change 'The Beths'). The path check stops the recursion from looping.
WITH RECURSIVE cobill AS (
    SELECT DISTINCT a.`artist_name` AS x, b.`artist_name` AS y
    FROM `PlaysAt` a
    JOIN `PlaysAt` b ON  b.`venue_name` = a.`venue_name`
                     AND b.`date_time`  = a.`date_time`
                     AND b.`artist_name` <> a.`artist_name`
), reach AS (
    SELECT y AS artist, 1 AS hops, CAST(CONCAT('The Beths', ' > ', y) AS CHAR(500)) AS path
    FROM cobill WHERE x = 'The Beths'
    UNION ALL
    SELECT c.y, r.hops + 1, CAST(CONCAT(r.path, ' > ', c.y) AS CHAR(500))
    FROM reach r
    JOIN cobill c ON c.x = r.artist
    WHERE r.hops < 4 AND LOCATE(CONCAT(c.y, ' >'), CONCAT(r.path, ' >')) = 0 AND c.y <> 'The Beths'
)
SELECT artist, hops AS degrees_of_separation, path
FROM (SELECT artist, hops, path,
             ROW_NUMBER() OVER (PARTITION BY artist ORDER BY hops, path) AS rn
      FROM reach) t
WHERE rn = 1
ORDER BY hops, artist;
 
-- D1. Rank artists by shows played at each venue.
SELECT `venue_name`, `artist_name`, COUNT(*) AS shows_played,
       RANK() OVER (PARTITION BY `venue_name` ORDER BY COUNT(*) DESC) AS venue_rank
FROM `PlaysAt`
GROUP BY `venue_name`, `artist_name`
ORDER BY `venue_name`, venue_rank, `artist_name`;
 
-- D2. Each artist's show and the one after it.
SELECT `artist_name`, `venue_name`, `date_time`,
       LEAD(`date_time`) OVER w AS next_show,
       DATEDIFF(LEAD(`date_time`) OVER w, `date_time`) AS days_until_next
FROM `PlaysAt`
WINDOW w AS (PARTITION BY `artist_name` ORDER BY `date_time`)
ORDER BY `artist_name`, `date_time`;
 
-- E. Public "similar artists" view: every artist, who is similar, and how much.
CREATE OR REPLACE VIEW `v_public_similar_artists` AS
SELECT x.`artist_name` AS artist, y.`artist_name` AS similar_artist,
       COUNT(*) AS shared_genres,
       GROUP_CONCAT(x.`genre` ORDER BY x.`genre` SEPARATOR ', ') AS genres
FROM `ArtistGenre` x
JOIN `ArtistGenre` y ON x.`genre` = y.`genre` AND x.`artist_name` <> y.`artist_name`
GROUP BY x.`artist_name`, y.`artist_name`;
 
GRANT SELECT ON `showsdb`.`v_public_similar_artists`
    TO 'fan_role','artist_role','promoter_role','venue_role';
 