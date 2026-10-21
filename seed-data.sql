-- Insert Venues

INSERT INTO `Venue` (`name`, `address`, `tech_info`, `rate`, `hours`, `contact_info`, `capacity`, `liquor_19_plus`, `note`) VALUES
('Capital Ballroom', '858 Yates St, Victoria, BC', 'Full house PA, 32-ch digital desk', 1500.00, '19:00 - 02:00', 'booking@thecapitalballroom.com', 550, TRUE, 'Load-in via back alley'),
('Quadratic Sound', '655 Queens Ave, Victoria, BC', 'Quadraphonic sound system, backline available', 450.00, '18:00 - 23:30', 'info@quadraticsound.com', 150, FALSE, 'All-ages DIY community space');

-- Insert Artists
INSERT INTO `Artist` (`name`, `since`, `bio`, `bandcamp`, `contact_info`) VALUES
('The Beths', '2014-06-01', 'Four-piece indie rock band.', 'https://thebethsnz.bandcamp.com', 'mgmt@thebeths.com'),
('Frog Eyes', '2001-01-15', 'Victoria-based indie art-rock band.', 'https://frogeyes.bandcamp.com', 'carey@frogeyes.ca'),
('Bootlicker', '2018-03-10', 'Hardcore punk from coastal BC.', 'https://bootlicker.bandcamp.com', 'bootlickerhc@gmail.com');

-- Insert 4NF Artist Members & Genres (Demonstrating MVD preservation without redundancy)
INSERT INTO `ArtistMember` (`artist_name`, `member_name`) VALUES
('The Beths', 'Elizabeth Stokes'),
('The Beths', 'Jonathan Pearce'),
('The Beths', 'Benjamin Sinclair'),
('The Beths', 'Tristan Deck'),
('Frog Eyes', 'Carey Mercer'),
('Frog Eyes', 'Melanie Campbell'),
('Bootlicker', 'Liam Hughes');

INSERT INTO `ArtistGenre` (`artist_name`, `genre`) VALUES
('The Beths', 'Indie Rock'),
('The Beths', 'Power Pop'),
('Frog Eyes', 'Indie Rock'),
('Frog Eyes', 'Art Rock'),
('Bootlicker', 'Hardcore Punk'),
('Bootlicker', 'D-Beat');

-- Insert Promoters & 4NF Promoter Genres
INSERT INTO `Promoter` (`name`, `since`, `bio`, `contact_info`) VALUES
('Atomique Productions', '2000-05-01', 'Independent concert and festival promoters.', 'info@atomiqueproductions.com'),
('Gigtoria Collective', '2021-09-01', 'DIY all-ages show bookings in Victoria.', 'gigtoria@protonmail.com');

INSERT INTO `PromoterGenre` (`promoter_name`, `genre`) VALUES
('Atomique Productions', 'Indie Rock'),
('Atomique Productions', 'Alternative'),
('Gigtoria Collective', 'Hardcore Punk'),
('Gigtoria Collective', 'Art Rock');

-- Insert Weak Entity Set: Shows
INSERT INTO `Shows` (`venue_name`, `date_time`, `name`, `all_ages`) VALUES
('Capital Ballroom', '2026-11-15 20:00:00', 'The Beths Autumn Tour', FALSE),
('Quadratic Sound', '2026-11-20 19:00:00', 'Island Punk & Art Showcase', TRUE),
('Capital Ballroom', '2026-09-12 20:00:00', 'End of Summer Indie Night', FALSE);

-- Insert Subsets: UpcomingShow & PastShow
INSERT INTO `UpcomingShow` (`venue_name`, `date_time`, `ticket_link`, `price`) VALUES
('Capital Ballroom', '2026-11-15 20:00:00', 'https://tickets.example.com/beths-vic', 35.00),
('Quadratic Sound', '2026-11-20 19:00:00', 'https://tickets.example.com/quad-showcase', 15.00);

INSERT INTO `PastShow` (`venue_name`, `date_time`, `footage`) VALUES
('Capital Ballroom', '2026-09-12 20:00:00', 'https://video.example.com/summer-indie-archive');

-- Insert Many-to-Many Relationships: PlaysAt, Books, Represents, Contact
INSERT INTO `PlaysAt` (`artist_name`, `venue_name`, `date_time`, `set_time`, `billing_order`) VALUES
('The Beths', 'Capital Ballroom', '2026-11-15 20:00:00', '21:30:00', 1),
('Frog Eyes', 'Capital Ballroom', '2026-11-15 20:00:00', '20:30:00', 2),
('Bootlicker', 'Quadratic Sound', '2026-11-20 19:00:00', '21:00:00', 1),
('Frog Eyes', 'Quadratic Sound', '2026-11-20 19:00:00', '19:45:00', 2),
('Frog Eyes', 'Capital Ballroom', '2026-09-12 20:00:00', '21:00:00', 1);

-- Demonstrating multiple promoters co-booking a single show
INSERT INTO `Books` (`promoter_name`, `venue_name`, `date_time`) VALUES
('Atomique Productions', 'Capital Ballroom', '2026-11-15 20:00:00'),
('Atomique Productions', 'Quadratic Sound', '2026-11-20 19:00:00'),
('Gigtoria Collective', 'Quadratic Sound', '2026-11-20 19:00:00'),
('Atomique Productions', 'Capital Ballroom', '2026-09-12 20:00:00');

INSERT INTO `Represents` (`artist_name`, `promoter_name`) VALUES
('The Beths', 'Atomique Productions'),
('Frog Eyes', 'Atomique Productions'),
('Bootlicker', 'Gigtoria Collective');

INSERT INTO `Contact` (`promoter_name`, `venue_name`) VALUES
('Atomique Productions', 'Capital Ballroom'),
('Atomique Productions', 'Quadratic Sound'),
('Gigtoria Collective', 'Quadratic Sound');
