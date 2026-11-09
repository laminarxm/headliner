-- =========================================================================
-- user-views.sql
-- 1. v_public_* : for everyone
-- 2. v_industry_* : for artists, promoters, venues (requires login)
-- 3. v_personal_* : for logged-in acc (shows personal data)
-- run order:
-- =========================================================================
USE showsdb;

DROP FUNCTION IF EXISTS `current_app_user`;
DELIMITER $$
CREATE FUNCTION `current_app_user`() RETURNS VARCHAR(32)
    NOT DETERMINISTIC NO SQL SQL SECURITY DEFINER
BEGIN
    RETURN SUBSTRING_INDEX(USER(), '@', 1);
END$$
DELIMITER ;


-- =========================================================================
-- PUBLIC VIEW
-- =========================================================================
CREATE OR REPLACE VIEW `v_public_artists` AS
SELECT a.`name`, a.`since`, a.`bio`, a.`bandcamp`,
       (SELECT GROUP_CONCAT(g.`genre` ORDER BY g.`genre` SEPARATOR ', ')
          FROM `ArtistGenre` g WHERE g.`artist_name` = a.`name`)   AS `genres`,
       (SELECT GROUP_CONCAT(m.`member_name` ORDER BY m.`member_name` SEPARATOR ', ')
          FROM `ArtistMember` m WHERE m.`artist_name` = a.`name`)  AS `members`
FROM `Artist` a;
 
CREATE OR REPLACE VIEW `v_public_venues` AS
SELECT `name`, `address`, `hours`, `capacity`, `liquor_19_plus`
FROM `Venue`;
 
CREATE OR REPLACE VIEW `v_public_upcoming_shows` AS
SELECT s.`name` AS `show_name`, s.`venue_name`, v.`address`, s.`date_time`,
       s.`all_ages`, u.`price`, u.`ticket_link`,
       (SELECT GROUP_CONCAT(p.`artist_name` ORDER BY p.`billing_order` SEPARATOR ', ')
          FROM `PlaysAt` p
         WHERE p.`venue_name` = s.`venue_name`
           AND p.`date_time`  = s.`date_time`)                     AS `lineup`
FROM `Shows` s
JOIN `UpcomingShow` u ON u.`venue_name` = s.`venue_name` AND u.`date_time` = s.`date_time`
JOIN `Venue` v        ON v.`name` = s.`venue_name`;
 
CREATE OR REPLACE VIEW `v_public_past_shows` AS
SELECT s.`name` AS `show_name`, s.`venue_name`, s.`date_time`,
       (SELECT p.`artist_name` FROM `PlaysAt` p
         WHERE p.`venue_name` = s.`venue_name`
           AND p.`date_time`  = s.`date_time`
           AND p.`billing_order` = 1)                              AS `headliner`,
       ps.`footage`
FROM `Shows` s
JOIN `PastShow` ps ON ps.`venue_name` = s.`venue_name` AND ps.`date_time` = s.`date_time`;


-- =========================================================================
-- INDUSTRY VIEW
-- =========================================================================
CREATE OR REPLACE VIEW `v_industry_artists` AS
SELECT a.`name`, a.`since`, a.`bio`, a.`bandcamp`, a.`contact_info`,
       (SELECT GROUP_CONCAT(g.`genre` ORDER BY g.`genre` SEPARATOR ', ')
          FROM `ArtistGenre` g WHERE g.`artist_name` = a.`name`)   AS `genres`,
       (SELECT GROUP_CONCAT(m.`member_name` ORDER BY m.`member_name` SEPARATOR ', ')
          FROM `ArtistMember` m WHERE m.`artist_name` = a.`name`)  AS `members`
FROM `Artist` a;
 
CREATE OR REPLACE VIEW `v_industry_promoters` AS
SELECT p.`name`, p.`since`, p.`bio`, p.`contact_info`,
       (SELECT GROUP_CONCAT(g.`genre` ORDER BY g.`genre` SEPARATOR ', ')
          FROM `PromoterGenre` g WHERE g.`promoter_name` = p.`name`) AS `genres`
FROM `Promoter` p;
 
CREATE OR REPLACE VIEW `v_industry_venues` AS
SELECT `name`, `address`, `capacity`, `hours`, `liquor_19_plus`,
       `rate`, `tech_info`, `contact_info`, `note`
FROM `Venue`;


-- =========================================================================
-- PERSONAL VIEW
-- =========================================================================

-- ARTIST -------------------------------------------------------------------
CREATE OR REPLACE VIEW `v_personal_artist_profile` AS
SELECT `name`, `since`, `bio`, `bandcamp`, `contact_info`
FROM `Artist`
WHERE `name` IN (SELECT `artist_name` FROM `UserArtist`
                  WHERE `username` = `current_app_user`())
WITH CHECK OPTION;
 
CREATE OR REPLACE VIEW `v_personal_artist_shows` AS
SELECT p.`artist_name`, s.`name` AS `show_name`, s.`venue_name`, s.`date_time`,
       p.`set_time`, p.`billing_order`,
       u.`price`, u.`ticket_link`, ps.`footage`,
       CASE WHEN u.`venue_name` IS NOT NULL THEN 'upcoming'
            WHEN ps.`venue_name` IS NOT NULL THEN 'past'
            ELSE 'unclassified' END                                 AS `status`
FROM `PlaysAt` p
JOIN `Shows` s ON s.`venue_name` = p.`venue_name` AND s.`date_time` = p.`date_time`
LEFT JOIN `UpcomingShow` u  ON u.`venue_name`  = s.`venue_name` AND u.`date_time`  = s.`date_time`
LEFT JOIN `PastShow`     ps ON ps.`venue_name` = s.`venue_name` AND ps.`date_time` = s.`date_time`
WHERE p.`artist_name` IN (SELECT `artist_name` FROM `UserArtist`
                           WHERE `username` = `current_app_user`());
 
-- PROMOTER -----------------------------------------------------------------
CREATE OR REPLACE VIEW `v_personal_promoter_profile` AS
SELECT `name`, `since`, `bio`, `contact_info`
FROM `Promoter`
WHERE `name` IN (SELECT `promoter_name` FROM `UserPromoter`
                  WHERE `username` = `current_app_user`())
WITH CHECK OPTION;
 
CREATE OR REPLACE VIEW `v_personal_bookings` AS
SELECT b.`promoter_name`, s.`name` AS `show_name`, s.`venue_name`, s.`date_time`,
       s.`all_ages`, u.`price`, u.`ticket_link`, ps.`footage`,
       CASE WHEN u.`venue_name` IS NOT NULL THEN 'upcoming'
            WHEN ps.`venue_name` IS NOT NULL THEN 'past'
            ELSE 'unclassified' END                                 AS `status`,
       (SELECT GROUP_CONCAT(p.`artist_name` ORDER BY p.`billing_order` SEPARATOR ', ')
          FROM `PlaysAt` p
         WHERE p.`venue_name` = s.`venue_name`
           AND p.`date_time`  = s.`date_time`)                     AS `lineup`
FROM `Books` b
JOIN `Shows` s ON s.`venue_name` = b.`venue_name` AND s.`date_time` = b.`date_time`
LEFT JOIN `UpcomingShow` u  ON u.`venue_name`  = s.`venue_name` AND u.`date_time`  = s.`date_time`
LEFT JOIN `PastShow`     ps ON ps.`venue_name` = s.`venue_name` AND ps.`date_time` = s.`date_time`
WHERE b.`promoter_name` IN (SELECT `promoter_name` FROM `UserPromoter`
                             WHERE `username` = `current_app_user`());
 
-- VENUE MANAGER ------------------------------------------------------------
CREATE OR REPLACE VIEW `v_personal_venue_profile` AS
SELECT `name`, `address`, `tech_info`, `rate`, `hours`, `contact_info`,
       `capacity`, `liquor_19_plus`, `note`
FROM `Venue`
WHERE `name` IN (SELECT `venue_name` FROM `UserVenue`
                  WHERE `username` = `current_app_user`())
WITH CHECK OPTION;
 
CREATE OR REPLACE VIEW `v_personal_venue_shows` AS
SELECT s.`venue_name`, v.`rate`, s.`name` AS `show_name`, s.`date_time`, s.`all_ages`,
       u.`price`, u.`ticket_link`, ps.`footage`,
       CASE WHEN u.`venue_name` IS NOT NULL THEN 'upcoming'
            WHEN ps.`venue_name` IS NOT NULL THEN 'past'
            ELSE 'unclassified' END                                 AS `status`,
       (SELECT GROUP_CONCAT(b.`promoter_name` ORDER BY b.`promoter_name` SEPARATOR ', ')
          FROM `Books` b
         WHERE b.`venue_name` = s.`venue_name`
           AND b.`date_time`  = s.`date_time`)                     AS `promoters`,
       (SELECT GROUP_CONCAT(p.`artist_name` ORDER BY p.`billing_order` SEPARATOR ', ')
          FROM `PlaysAt` p
         WHERE p.`venue_name` = s.`venue_name`
           AND p.`date_time`  = s.`date_time`)                     AS `lineup`
FROM `Shows` s
JOIN `Venue` v ON v.`name` = s.`venue_name`
LEFT JOIN `UpcomingShow` u  ON u.`venue_name`  = s.`venue_name` AND u.`date_time`  = s.`date_time`
LEFT JOIN `PastShow`     ps ON ps.`venue_name` = s.`venue_name` AND ps.`date_time` = s.`date_time`
WHERE s.`venue_name` IN (SELECT `venue_name` FROM `UserVenue`
                          WHERE `username` = `current_app_user`());