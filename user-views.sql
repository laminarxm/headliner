-- =========================================================================
-- user-views.sql
-- 1. v_public_* : for everyone
-- 2. v_industry_* : for artists, promoters, venues (requires login)
-- 3. v_personal_* : for logged-in acc (shows personal data)
-- Run-Order:
-- =========================================================================
USE 'showsdb';

-- =========================================================================
-- PUBLIC VIEW
-- =========================================================================
CREATE OR REPLACE VIEW 'v_public_artists' AS
SELECT a.'name', a.'since', a.'bio', a.'bandcamp',
    (SELECT GROUP_CONCAT (g.'genre' ORDER BY g.'genre' SEPARATOR ', ')
        FROM 'ArtistGenre' g WHERE g.'artist_name' = a.'name') AS 'genres',
    (SELECT GROUP_CONCAT (m.'member_name' ORDER BY m.'member_name' SEPARATOR ', ')
        FROM 'ArtistMember' m WHERE m.'artist_name' = a.'name') AS 'members'
FROM 'Artist' a;

CREATE OR REPLACE VIEW 'v_public_venues' AS
SELECT 'name', 'address', 'hours', 'capacity', 'liquor_19_plus'
FROM 'VENUE';

CREATE OR REPLACE VIEW 'v_public_upcoming_shows' AS
SELECT s.'name' AS 'show_name', s.'venue_name', v.'address', s.'date_name',
    s.'all_ages', u.'price', u.'ticket_link',
    (SELECT GROUP_CONCAT(p.`artist_name` ORDER BY p.`billing_order` SEPARATOR ', ')
        FROM `PlaysAt` p
        WHERE p.`venue_name` = s.`venue_name`
        AND p.`date_time`  = s.`date_time`) AS `lineup`
FROM `Shows` s
JOIN `UpcomingShow` u ON u.`venue_name` = s.`venue_name` AND u.`date_time` = s.`date_time`
JOIN `Venue` v ON v.`name` = s.`venue_name`;

CREATE OR REPLACE VIEW `v_public_past_shows` AS
SELECT s.`name` AS `show_name`, s.`venue_name`, s.`date_time`,
       (SELECT p.`artist_name` FROM `PlaysAt` p
        WHERE p.`venue_name` = s.`venue_name`
        AND p.`date_time`  = s.`date_time`
        AND p.`billing_order` = 1) AS `headliner`, 
    ps.`footage`
FROM `Shows` s
JOIN `PastShow` ps ON ps.`venue_name` = s.`venue_name` AND ps.`date_time` = s.`date_time`;

-- =========================================================================
-- INDUSTRY VIEW
-- =========================================================================

-- =========================================================================
-- PERSONAL VIEW
-- =========================================================================
