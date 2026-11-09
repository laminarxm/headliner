#!/usr/bin/env bash
# test-permissions.sh -- log in as each demo user and show what they can / can't do.
# Usage (after running the five .sql files (build-shows, seed-data, user-views, procedures, permissions) as root):   bash test-permissions.sh
# Each command below is its own login, so a permission error doesn't stop the demo.
# Demo passwords are '<user>pw' (see permissions.sql).
 
run() {   # run <user> "<sql>"
  local user="$1"; shift
  echo; echo ">>> [$user] $*"
  mysql -t -u"$user" -p"${user}pw" showsdb -e "$*" 2>&1 | grep -v 'Using a password'
}
 
echo "################ 1. FAN (basic user) ################"
run fan1 "SELECT name, genres, members FROM v_public_artists;"
run fan1 "SELECT show_name, venue_name, date_time, price, lineup FROM v_public_upcoming_shows;"
run fan1 "SELECT * FROM v_public_past_shows;"
run fan1 "SELECT * FROM Artist;"                      # DENIED: no base-table access
run fan1 "SELECT contact_info FROM v_industry_artists;" # DENIED: contact info is industry-only
run fan1 "SELECT * FROM v_personal_artist_profile;"         # DENIED: not an artist
 
echo; echo "################ 2. ARTIST (alice manages The Beths) ################"
run alice "SELECT * FROM v_personal_artist_profile;"        # only The Beths
run alice "UPDATE v_personal_artist_profile SET bio='Four-piece indie rock band from Auckland.' WHERE name='The Beths'; SELECT ROW_COUNT() AS rows_changed;"
run alice "UPDATE v_personal_artist_profile SET bio='hijacked' WHERE name='Frog Eyes'; SELECT ROW_COUNT() AS rows_changed;"   # 0 rows changed
run alice "UPDATE v_personal_artist_profile SET name='The Beths 2' WHERE name='The Beths'; SELECT ROW_COUNT() AS rows_changed;" # DENIED: no column grant on name
run alice "SELECT * FROM v_personal_artist_shows;"
run alice "SELECT name, contact_info FROM v_industry_promoters;"   # artists can see promoter contacts
run alice "SELECT * FROM v_personal_bookings;"              # DENIED: not a promoter
 
echo; echo "################ 3. PROMOTER (pat = Atomique, gina = Gigtoria) ################"
run pat  "SELECT promoter_name, show_name, date_time, status, lineup FROM v_personal_bookings ORDER BY date_time;"
run gina "SELECT promoter_name, show_name, date_time, status, lineup FROM v_personal_bookings ORDER BY date_time;"
run pat  "CALL add_show('Quadratic Sound', '2027-02-01 19:00:00', 'Winter Showcase', TRUE, 12.00, 'https://tickets.example.com/winter', 'Atomique Productions');"
run pat  "CALL add_artist_to_lineup('Quadratic Sound', '2027-02-01 19:00:00', 'Bootlicker', '20:00:00', 1);"
run pat  "SELECT show_name, status, lineup FROM v_personal_bookings ORDER BY date_time;"
run pat  "CALL add_show('Quadratic Sound', '2027-03-01 19:00:00', 'Not Mine', TRUE, 5, NULL, 'Gigtoria Collective');"  # rejected: not their promoter
run pat  "CALL add_show('Quadratic Sound', '2020-01-01 19:00:00', 'In The Past', TRUE, 5, NULL, 'Atomique Productions');" # rejected: past date
run gina "CALL add_artist_to_lineup('Quadratic Sound', '2027-02-01 19:00:00', 'Frog Eyes', '19:00:00', 2);"  # rejected: gina doesn't book it
run pat  "INSERT INTO Shows VALUES ('Quadratic Sound','2027-05-05 19:00:00','Sneaky',TRUE);"  # DENIED: no base-table INSERT
 
echo; echo "################ 4. VENUE MANAGER (vera = Capital Ballroom) ################"
run vera "SELECT * FROM v_personal_venue_profile;"
run vera "SELECT venue_name, show_name, date_time, status, promoters, lineup FROM v_personal_venue_shows ORDER BY date_time;"
run vera "UPDATE v_personal_venue_profile SET rate=1600.00 WHERE name='Capital Ballroom'; SELECT ROW_COUNT() AS rows_changed;"
run vera "UPDATE v_personal_venue_profile SET rate=1.00 WHERE name='Quadratic Sound'; SELECT ROW_COUNT() AS rows_changed;"     # 0 rows changed (not hers)
run vera "CALL add_show('Quadratic Sound', '2027-04-01 19:00:00', 'Wrong Venue', TRUE, 5, NULL, NULL);"  # rejected
run vera "CALL add_show('Capital Ballroom', '2027-04-01 20:00:00', 'Spring Fling', FALSE, 25, NULL, NULL);"
run vera "SELECT show_name, date_time, status, promoters FROM v_personal_venue_shows ORDER BY date_time;"
 