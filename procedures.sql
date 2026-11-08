-- -------------------------------------------------------------------------
-- procedures.sql - controlled write paths (transactions + ownership checks)
-- notes:
-- run order: after build-shows.sql, seed-data.sql, and user-views.sql
-- -------------------------------------------------------------------------
USE `showsdb`;
 
DROP PROCEDURE IF EXISTS `add_show`;
DROP PROCEDURE IF EXISTS `add_artist_to_lineup`;
DROP PROCEDURE IF EXISTS `archive_past_shows`;
DROP EVENT IF EXISTS `ev_archive_past_shows`;
 
DELIMITER $$
 
-- -------------------------------------------------------------------------
-- add_show: create a new UPCOMING show atomically (Shows + UpcomingShow +
-- optionally Books). Pass p_promoter to book it as that promoter (caller must
-- manage that promoter), or NULL to add it as manager of the venue.
-- -------------------------------------------------------------------------
CREATE PROCEDURE `add_show`(
    IN p_venue       VARCHAR(100),
    IN p_when        DATETIME,
    IN p_name        VARCHAR(150),
    IN p_all_ages    BOOLEAN,
    IN p_price       DECIMAL(8,2),
    IN p_ticket_link VARCHAR(255),
    IN p_promoter    VARCHAR(100)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
 
    IF NOT EXISTS (SELECT 1 FROM `Venue` WHERE `name` = p_venue) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'add_show: no such venue';
    END IF;
 
    IF p_when <= NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'add_show: date_time must be in the future';
    END IF;
 
    IF p_promoter IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM `UserPromoter`
                        WHERE `username` = `current_app_user`()
                          AND `promoter_name` = p_promoter) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'add_show: you do not manage that promoter';
        END IF;
    ELSEIF NOT EXISTS (SELECT 1 FROM `UserVenue`
                        WHERE `username` = `current_app_user`()
                          AND `venue_name` = p_venue) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'add_show: you do not manage that venue';
    END IF;
 
    START TRANSACTION;
        INSERT INTO `Shows` (`venue_name`, `date_time`, `name`, `all_ages`)
        VALUES (p_venue, p_when, p_name, p_all_ages);
 
        INSERT INTO `UpcomingShow` (`venue_name`, `date_time`, `ticket_link`, `price`)
        VALUES (p_venue, p_when, p_ticket_link, IFNULL(p_price, 0.00));
 
        IF p_promoter IS NOT NULL THEN
            INSERT INTO `Books` (`promoter_name`, `venue_name`, `date_time`)
            VALUES (p_promoter, p_venue, p_when);
        END IF;
    COMMIT;
END$$
 
-- -------------------------------------------------------------------------
-- add_artist_to_lineup: put an artist on an UPCOMING show. Allowed for the
-- manager of the venue, or a promoter who is booking that show.
-- -------------------------------------------------------------------------
CREATE PROCEDURE `add_artist_to_lineup`(
    IN p_venue         VARCHAR(100),
    IN p_when          DATETIME,
    IN p_artist        VARCHAR(100),
    IN p_set_time      TIME,
    IN p_billing_order INT UNSIGNED
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
 
    IF NOT EXISTS (SELECT 1 FROM `UpcomingShow`
                    WHERE `venue_name` = p_venue AND `date_time` = p_when) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'add_artist_to_lineup: no such upcoming show';
    END IF;
 
    IF NOT EXISTS (SELECT 1 FROM `UserVenue`
                    WHERE `username` = `current_app_user`() AND `venue_name` = p_venue)
       AND NOT EXISTS (SELECT 1
                         FROM `Books` b
                         JOIN `UserPromoter` up ON up.`promoter_name` = b.`promoter_name`
                        WHERE up.`username` = `current_app_user`()
                          AND b.`venue_name` = p_venue
                          AND b.`date_time`  = p_when) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'add_artist_to_lineup: you do not manage this venue or book this show';
    END IF;
 
    START TRANSACTION;
        INSERT INTO `PlaysAt` (`artist_name`, `venue_name`, `date_time`, `set_time`, `billing_order`)
        VALUES (p_artist, p_venue, p_when, p_set_time, p_billing_order);
    COMMIT;
END$$
 
-- -------------------------------------------------------------------------
-- archive_past_shows: replaces the "becomes" diamond in the ER diagram.
-- Moves every show whose date has passed from UpcomingShow to PastShow.
-- Admin-only (no role is granted EXECUTE); also run daily by the event below.
-- NOW() is fixed for the whole call, so INSERT and DELETE see the same rows.
-- -------------------------------------------------------------------------
CREATE PROCEDURE `archive_past_shows`()
BEGIN
    DECLARE v_moved INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
 
    START TRANSACTION;
        INSERT INTO `PastShow` (`venue_name`, `date_time`)
        SELECT `venue_name`, `date_time` FROM `UpcomingShow` WHERE `date_time` < NOW();
        SET v_moved = ROW_COUNT();
 
        DELETE FROM `UpcomingShow` WHERE `date_time` < NOW();
    COMMIT;
 
    SELECT v_moved AS `shows_archived`;
END$$
 
DELIMITER ;
 
-- Runs the archive once a day. Needs:  SET GLOBAL event_scheduler = ON;
CREATE EVENT `ev_archive_past_shows`
    ON SCHEDULE EVERY 1 DAY
    DO CALL `archive_past_shows`();
 