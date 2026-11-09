USE showsdb;


-- Query 1: Join Weak Entity (`Shows`), Inheritance Subclass (`UpcomingShow`),
-- and Lineup (`PlaysAt`) to display upcoming lineups sorted by date and billing order.



SELECT 
    s.`name` AS `show_name`,
    s.`venue_name`,
    s.`date_time`,
    p.`artist_name`,
    p.`set_time`,
    p.`billing_order`,
    u.`price`,
    u.`ticket_link`
FROM `Shows` s
JOIN `UpcomingShow` u 
    ON s.`venue_name` = u.`venue_name` AND s.`date_time` = u.`date_time`
JOIN `PlaysAt` p 
    ON s.`venue_name` = p.`venue_name` AND s.`date_time` = p.`date_time`
WHERE u.`price` <= 40.00
ORDER BY s.`date_time` ASC, p.`billing_order` ASC;





-- Query 2: Query across 4NF decomposed tables (`Artist`, `ArtistGenre`, `ArtistMember`)
-- to retrieve all members of 'Indie Rock' bands.




SELECT 
    a.`name` AS `artist_name`,
    ag.`genre`,
    am.`member_name`,
    a.`bandcamp`
FROM `Artist` a
JOIN `ArtistGenre` ag ON a.`name` = ag.`artist_name`
JOIN `ArtistMember` am ON a.`name` = am.`artist_name`
WHERE ag.`genre` = 'Indie Rock'
ORDER BY a.`name` ASC, am.`member_name` ASC;

-- Query 3: Join `Shows`, `Venue`, and `Books` to find all-ages shows and their co-promoters.





SELECT 
    s.`name` AS `show_name`,
    s.`venue_name`,
    v.`address`,
    v.`capacity`,
    b.`promoter_name`
FROM `Shows` s
JOIN `Venue` v ON s.`venue_name` = v.`name`
JOIN `Books` b ON s.`venue_name` = b.`venue_name` AND s.`date_time` = b.`date_time`
WHERE s.`all_ages` = TRUE
ORDER BY b.`promoter_name` ASC;

-- Query 4: Retrieve archived footage for past shows along with headlining artist.





SELECT 
    s.`name` AS `show_name`,
    s.`venue_name`,
    s.`date_time`,
    pa.`artist_name` AS `headliner`,
    ps.`footage`
FROM `Shows` s
JOIN `PastShow` ps 
    ON s.`venue_name` = ps.`venue_name` AND s.`date_time` = ps.`date_time`
JOIN `PlaysAt` pa 
    ON s.`venue_name` = pa.`venue_name` AND s.`date_time` = pa.`date_time`
WHERE pa.`billing_order` = 1;


-- =========================================================================
-- Queries 5-8: the same questions as above, asked through the views
-- (run views.sql first). Results should match Queries 1, 2 and 4.
-- =========================================================================

-- Query 5: public upcoming shows with lineup (replaces the 3-table join in Query 1)
SELECT * FROM `v_public_upcoming_shows` ORDER BY `date_time`;

-- Query 6: public artist directory with members and genres in ONE row each
-- (compare with Query 2, which needed a join across the 4NF tables)
SELECT * FROM `v_public_artists`;

-- Query 7: past shows with footage and headliner (replaces Query 4)
SELECT * FROM `v_public_past_shows`;

-- Query 8: the industry view of venues, including the private columns
SELECT `name`, `rate`, `tech_info`, `contact_info` FROM `v_industry_venues`;

-- NOTE: the v_personal_* views filter on the *logged-in* MySQL user, so they return
-- nothing when run as root. Log in as alice / pat / vera to see them
-- (see test-roles.sh).