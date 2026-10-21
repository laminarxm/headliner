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
