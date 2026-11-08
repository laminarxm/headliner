-- =========================================================================
-- build-shows.sql - schema for local-shows
-- Run Order: build-shows -> seed-data.sql -> views.sql -> procedures.sql 
-- -> permissions.sql
-- note: DROPS script allows for database to be re-run
-- =========================================================================
DROP DATABASE IF EXISTS 'showsdb';
CREATE DATABASE 'showsdb' CHARACTER SET utf8mb4;
USE 'showsdb';

-- =========================================================================
-- 1. STRONG ENTITY SETS (BCNF & 4NF Single-Valued Attributes)
-- =========================================================================

CREATE TABLE `Venue` (
    `name` VARCHAR(100) PRIMARY KEY,
    `address` VARCHAR(255) NOT NULL,
    `tech_info` TEXT,
    `rate` DECIMAL(10, 2),
    `hours` VARCHAR(100),
    `contact_info` VARCHAR(255) NOT NULL,
    `capacity` INT UNSIGNED,
    `liquor_19_plus` BOOLEAN NOT NULL DEFAULT FALSE,
    `note` TEXT
);

CREATE TABLE `Artist` (
    `name` VARCHAR(100) PRIMARY KEY,
    `since` DATE,
    `bio` TEXT,
    `bandcamp` VARCHAR(255),
    `contact_info` VARCHAR(255) NOT NULL
);

CREATE TABLE `Promoter` (
    `name` VARCHAR(100) PRIMARY KEY,
    `since` DATE,
    `bio` TEXT,
    `contact_info` VARCHAR(255) NOT NULL
);

-- =========================================================================
-- 2. 4NF DECOMPOSED RELATIONS (Preserving MVDs)
-- Isolates independent multi-valued attributes:
--   artist_name ->> member_name
--   artist_name ->> genre
--   promoter_name ->> genre
-- =========================================================================


CREATE TABLE `ArtistMember` (
    `artist_name` VARCHAR(100),
    `member_name` VARCHAR(100),
    PRIMARY KEY (`artist_name`, `member_name`),
    FOREIGN KEY (`artist_name`) REFERENCES `Artist`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE `ArtistGenre` (
    `artist_name` VARCHAR(100),
    `genre` VARCHAR(50),
    PRIMARY KEY (`artist_name`, `genre`),
    FOREIGN KEY (`artist_name`) REFERENCES `Artist`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE `PromoterGenre` (
    `promoter_name` VARCHAR(100),
    `genre` VARCHAR(50),
    PRIMARY KEY (`promoter_name`, `genre`),
    FOREIGN KEY (`promoter_name`) REFERENCES `Promoter`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =========================================================================
-- 3. WEAK ENTITY SET: SHOWS (Supported by VENUE via "happen @")
-- Recognizable in SQL DDL because PART OF the primary key (`venue_name`)
-- is also a foreign key referencing `Venue`(`name`).
-- =========================================================================

CREATE TABLE `Shows` (
    `venue_name` VARCHAR(100),
    `date_time` DATETIME,
    `name` VARCHAR(150) NOT NULL,
    `all_ages` BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (`venue_name`, `date_time`),
    FOREIGN KEY (`venue_name`) REFERENCES `Venue`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =========================================================================
-- 4. INHERITANCE SUBSETS ("isa" Subclasses of SHOWS)
-- Matches the subset pattern where the ENTIRE primary key of the subclass
-- is also a foreign key referencing the superclass primary key.
-- =========================================================================

CREATE TABLE `UpcomingShow` (
    `venue_name` VARCHAR(100),
    `date_time` DATETIME,
    `ticket_link` VARCHAR(255),
    `price` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (`venue_name`, `date_time`),
    FOREIGN KEY (`venue_name`, `date_time`) REFERENCES `Shows`(`venue_name`, `date_time`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE `PastShow` (
    `venue_name` VARCHAR(100),
    `date_time` DATETIME,
    `footage` VARCHAR(255),
    PRIMARY KEY (`venue_name`, `date_time`),
    FOREIGN KEY (`venue_name`, `date_time`) REFERENCES `Shows`(`venue_name`, `date_time`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =========================================================================
-- 5. MANY-TO-MANY RELATIONSHIP RELATIONS
-- For each involved entity set, its identifiers become attributes, any
-- relationship attributes are included, and the combination of foreign
-- identifiers forms the primary key.
-- =========================================================================

-- Relationship: ARTIST — plays @ — SHOWS[cite: 2, 4]
CREATE TABLE `PlaysAt` (
    `artist_name` VARCHAR(100),
    `venue_name` VARCHAR(100),
    `date_time` DATETIME,
    `set_time` TIME,
    `billing_order` INT UNSIGNED,
    PRIMARY KEY (`artist_name`, `venue_name`, `date_time`),
    FOREIGN KEY (`artist_name`) REFERENCES `Artist`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`venue_name`, `date_time`) REFERENCES `Shows`(`venue_name`, `date_time`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Relationship: PROMOTER — books — SHOWS
CREATE TABLE `Books` (
    `promoter_name` VARCHAR(100),
    `venue_name` VARCHAR(100),
    `date_time` DATETIME,
    PRIMARY KEY (`promoter_name`, `venue_name`, `date_time`),
    FOREIGN KEY (`promoter_name`) REFERENCES `Promoter`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`venue_name`, `date_time`) REFERENCES `Shows`(`venue_name`, `date_time`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Relationship: ARTIST — represents — PROMOTER
CREATE TABLE `Represents` (
    `artist_name` VARCHAR(100),
    `promoter_name` VARCHAR(100),
    PRIMARY KEY (`artist_name`, `promoter_name`),
    FOREIGN KEY (`artist_name`) REFERENCES `Artist`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`promoter_name`) REFERENCES `Promoter`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Relationship: PROMOTER — contact — VENUE
CREATE TABLE `Contact` (
    `promoter_name` VARCHAR(100),
    `venue_name` VARCHAR(100),
    PRIMARY KEY (`promoter_name`, `venue_name`),
    FOREIGN KEY (`promoter_name`) REFERENCES `Promoter`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`venue_name`) REFERENCES `Venue`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =========================================================================
-- 6. USER ACCOUNTS
-- Integrates user-views.sql
-- App.username must match the MySQL account name (ex. 'alice')
-- There is no 'role' column asa person's role(s) is derived from where they
-- appear in linked table(s) (storing role twice could cause a disagreement).
-- For example, a musician can also be a promoter
-- Each link table is many-to-many: a band can have several managers, and one
-- person can manage several acts. Separate link tables (rather than one
-- generic (entity_type, entity_name) table) keep real foreign keys.
-- =========================================================================

CREATE TABLE 'AppUser' (
    'username' VARCHAR(50) PRIMARY KEY,
    'display_name' VARCHAR(100) NOT NULL,
    'email' VARCHAR(200)
);

CREATE TABLE 'UserArtist' (
    'username' VARCHAR(50),
    'artist_name' VARCHAR(100) NOT NULL,
    PRIMARY KEY ('username', 'artist_name'),
    FOREIGN KEY ('username') REFERENCES 'AppUser' ('username')
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ('artist_name') REFERENCES 'Artist' ('name')
        ON DELETE CASCADE ON UPDATE CASCADE,
);

CREATE TABLE 'UserPromoter' (
    'username' VARCHAR(50),
    'promoter_name' VARCHAR(100) NOT NULL,
    PRIMARY KEY ('username', 'promoter_name'),
    FOREIGN KEY ('username') REFERENCES 'AppUser' ('username')
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ('promoter_name') REFERENCES 'Promoter' ('name')
        ON DELETE CASCADE ON UPDATE CASCADE,
);

CREATE TABLE 'UserVenue' (
    'username' VARCHAR(50),
    'venue_name' VARCHAR(100) NOT NULL,
    PRIMARY KEY ('username', 'venue_name'),
    FOREIGN KEY ('username') REFERENCES 'AppUser' ('username')
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ('venue_name') REFERENCES 'Venue' ('name')
        ON DELETE CASCADE ON UPDATE CASCADE,
);