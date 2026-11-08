-- =========================================================================
-- permissions.sql 
-- notes:
-- run order: run last
-- =========================================================================
USE `showsdb`;
 
DROP USER IF EXISTS 'fan1'@'localhost', 'alice'@'localhost', 'carey'@'localhost',
                    'pat'@'localhost',  'gina'@'localhost',  'vera'@'localhost',
                    'quinn'@'localhost';
DROP ROLE IF EXISTS 'fan_role', 'artist_role', 'promoter_role', 'venue_role';
 
CREATE ROLE 'fan_role', 'artist_role', 'promoter_role', 'venue_role';
 
-- Everyone (including fans): public views ----------------------------------
GRANT SELECT ON `showsdb`.`v_public_artists`        TO 'fan_role','artist_role','promoter_role','venue_role';
GRANT SELECT ON `showsdb`.`v_public_venues`         TO 'fan_role','artist_role','promoter_role','venue_role';
GRANT SELECT ON `showsdb`.`v_public_upcoming_shows` TO 'fan_role','artist_role','promoter_role','venue_role';
GRANT SELECT ON `showsdb`.`v_public_past_shows`     TO 'fan_role','artist_role','promoter_role','venue_role';
 
-- Industry roles: contact info and business details ------------------------
GRANT SELECT ON `showsdb`.`v_industry_artists`   TO 'artist_role','promoter_role','venue_role';
GRANT SELECT ON `showsdb`.`v_industry_promoters` TO 'artist_role','promoter_role','venue_role';
GRANT SELECT ON `showsdb`.`v_industry_venues`    TO 'artist_role','promoter_role','venue_role';
 
-- Artist -------------------------------------------------------------------
GRANT SELECT ON `showsdb`.`v_my_artist_profile` TO 'artist_role';
GRANT UPDATE (`bio`, `bandcamp`, `contact_info`)   -- not `name` (primary key) or `since`
    ON `showsdb`.`v_my_artist_profile` TO 'artist_role';
GRANT SELECT ON `showsdb`.`v_my_artist_shows` TO 'artist_role';
 
-- Promoter -----------------------------------------------------------------
GRANT SELECT ON `showsdb`.`v_my_promoter_profile` TO 'promoter_role';
GRANT UPDATE (`bio`, `contact_info`)
    ON `showsdb`.`v_my_promoter_profile` TO 'promoter_role';
GRANT SELECT ON `showsdb`.`v_my_bookings` TO 'promoter_role';
GRANT EXECUTE ON PROCEDURE `showsdb`.`add_show`             TO 'promoter_role';
GRANT EXECUTE ON PROCEDURE `showsdb`.`add_artist_to_lineup` TO 'promoter_role';
 
-- Venue manager ------------------------------------------------------------
GRANT SELECT ON `showsdb`.`v_my_venue_profile` TO 'venue_role';
GRANT UPDATE (`address`, `tech_info`, `rate`, `hours`, `contact_info`,
              `capacity`, `liquor_19_plus`, `note`)  -- everything except `name`
    ON `showsdb`.`v_my_venue_profile` TO 'venue_role';
GRANT SELECT ON `showsdb`.`v_my_venue_shows` TO 'venue_role';
GRANT EXECUTE ON PROCEDURE `showsdb`.`add_show`             TO 'venue_role';
GRANT EXECUTE ON PROCEDURE `showsdb`.`add_artist_to_lineup` TO 'venue_role';
 
-- Demo accounts (usernames match AppUser.username in seed-data.sql) ---------
CREATE USER 'fan1'@'localhost'  IDENTIFIED BY 'fan1pw';
CREATE USER 'alice'@'localhost' IDENTIFIED BY 'alicepw';
CREATE USER 'carey'@'localhost' IDENTIFIED BY 'careypw';
CREATE USER 'pat'@'localhost'   IDENTIFIED BY 'patpw';
CREATE USER 'gina'@'localhost'  IDENTIFIED BY 'ginapw';
CREATE USER 'vera'@'localhost'  IDENTIFIED BY 'verapw';
CREATE USER 'quinn'@'localhost' IDENTIFIED BY 'quinnpw';
 
GRANT 'fan_role'      TO 'fan1'@'localhost';
GRANT 'artist_role'   TO 'alice'@'localhost', 'carey'@'localhost';
GRANT 'promoter_role' TO 'pat'@'localhost',   'gina'@'localhost';
GRANT 'venue_role'    TO 'vera'@'localhost',  'quinn'@'localhost';
 
SET DEFAULT ROLE ALL TO 'fan1'@'localhost', 'alice'@'localhost', 'carey'@'localhost',
                        'pat'@'localhost',  'gina'@'localhost',  'vera'@'localhost',
                        'quinn'@'localhost';
 