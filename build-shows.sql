
-- =========================================================================
-- 1. STRONG ENTITY SETS (BCNF & 4NF Single-Valued Attributes)[cite: 1, 2, 10]
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
-- 2. 4NF DECOMPOSED RELATIONS (Preserving MVDs)[cite: 1, 2, 10]
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
-- 3. WEAK ENTITY SET: SHOWS (Supported by VENUE via "happen @")[cite: 1, 2, 9]
-- Recognizable in SQL DDL because PART OF the primary key (`venue_name`)
-- is also a foreign key referencing `Venue`(`name`)[cite: 9].
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
-- 4. INHERITANCE SUBSETS ("isa" Subclasses of SHOWS)[cite: 1, 2, 9, 11]
-- Matches the subset pattern where the ENTIRE primary key of the subclass
-- is also a foreign key referencing the superclass primary key[cite: 9, 11].
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
-- 5. MANY-TO-MANY RELATIONSHIP RELATIONS[cite: 2, 4]
-- For each involved entity set, its identifiers become attributes, any
-- relationship attributes are included, and the combination of foreign
-- identifiers forms the primary key[cite: 4].
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

-- Relationship: PROMOTER — books — SHOWS[cite: 2, 4]
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

-- Relationship: ARTIST — represents — PROMOTER[cite: 2, 4]
CREATE TABLE `Represents` (
    `artist_name` VARCHAR(100),
    `promoter_name` VARCHAR(100),
    PRIMARY KEY (`artist_name`, `promoter_name`),
    FOREIGN KEY (`artist_name`) REFERENCES `Artist`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`promoter_name`) REFERENCES `Promoter`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Relationship: PROMOTER — contact — VENUE[cite: 2, 4]
CREATE TABLE `Contact` (
    `promoter_name` VARCHAR(100),
    `venue_name` VARCHAR(100),
    PRIMARY KEY (`promoter_name`, `venue_name`),
    FOREIGN KEY (`promoter_name`) REFERENCES `Promoter`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`venue_name`) REFERENCES `Venue`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
);
