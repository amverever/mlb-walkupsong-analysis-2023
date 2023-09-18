
# Hear what music MLB players have chosen as their walk-up songs #

DROP DATABASE IF EXISTS walkupsong;
CREATE DATABASE IF NOT EXISTS walkupsong; 
USE walkupsong;

DROP TABLE IF EXISTS teams,
                     players,
                     players_song,
                     songs;
                     
CREATE TABLE teams (
	team_no 	INT		        NOT NULL,
    team_code  	VARCHAR(3)      NOT NULL PRIMARY KEY,
    team_name  	VARCHAR(30)     NOT NULL,
    league   	VARCHAR(3)      NOT NULL,
    division	VARCHAR(7)		NOT NULL
);

DROP TABLE IF EXISTS players;
CREATE TABLE players (
	player_no 	INT				NOT NULL auto_increment PRIMARY KEY,
    team_code 	VARCHAR(3)		NOT NULL,
    first_name	VARCHAR(20)		NOT NULL,
    last_name	VARCHAR(20)		NOT NULL,
    song		VARCHAR(255)	NOT NULL,
    song_code 	VARCHAR(10)		NULL
);

update players
set song = "Hotel Lobby"
where song_code = "s0137";


CREATE TABLE songs (
	song_code 		VARCHAR (10) 		NOT NULL PRIMARY KEY,
    song_name		VARCHAR (255)		NOT NULL,
    artist_name		VARCHAR (255)		NOT NULL,
    artist2_name	VARCHAR (255)		NULL
);

ALTER TABLE songs
MODIFY COLUMN song_name VARCHAR (255) NOT NULL;

UPDATE players p
   SET p.song = (SELECT s.song_name FROM songs s WHERE p.song_code = s.song_code);

    
    
INSERT INTO teams(team_no,team_code,team_name,league,division) VALUES
(1,"ARI","Arizona Diamondbacks","NL","West"),
(2,"ATL","Atlanta Braves","NL","East"),
(3,"BAL","Baltimore Orioles","AL","East"),
(4,"BOR","Boston Red Sox","AL","East"),
(5,"CHC","Chicago Cubs","NL","Central"),
(6,"CHW","Chicago White Sox","AL","Central"),
(7,"CIN","Cincinnati Reds","NL","Central"),
(8,"CLE","Cleveland Guardians","AL","Central"),
(9,"COL","Colorado Rockies","NL","West"),
(10,"DET","Detroit Tigers","AL","Central"),
(11,"HOU","Houston Astros","AL","West"),
(12,"KC","Kansas City Royals","AL","Central"),
(13,"LAA","Los Angeles Angels","AL","West"),
(14,"LAD","Los Angeles Dodgers","NL","West"),
(15,"MIA","Miami Marlins","NL","East"),
(16,"MIL","Milwaukee Brewers","NL","Central"),
(17,"MIN","Minnesota Twins","AL","Central"),
(18,"NYM","New York Mets","NL","East"),
(19,"NYY","New York Yankees","AL","East"),
(20,"OAK","Oakland Athletics","AL","West"),
(21,"PHI","Philadelphia Phillies","NL","East"),
(22,"PIT","Pittsburgh Pirates","NL","Central"),
(23,"SD","San Diego Padres","NL","West"),
(24,"SF","San Francisco Giants","NL","West"),
(25,"SEA","Seattle Mariners","AL","West"),
(26,"STL","St. Louis Cardinals","NL","Central"),
(27,"TB","Tampa Bay Rays","AL","East"),
(28,"TEX","Texas Rangers","AL","West"),
(29,"TOR","Toronto Blue Jays","AL","East"),
(30,"WSH","Washington Nationals","NL","East");


SELECT * FROM players;

SELECT *
FROM (
	SELECT song_code, artist_name, song_name, COUNT(song_name)
	FROM songs
	GROUP BY artist_name) as A
join (
	SELECT artist2_name, song_name, COUNT(song_name)
	FROM songs
	GROUP BY artist2_name) as B on A.song_name = B.song_name;
    
    
SELECT song_code, artist_name, song_name, count(song_name) as counts
FROM player_song
GROUP BY song_name
HAVING counts > 1
ORDER BY counts desc;

SELECT *
FROM player_song
WHERE song_name = "BUTTERFLY EFFECT";

UPDATE player_song
set artist2_name = "Clipse"
where song_name = "Use This Gospel";

commit;

# REMOVE DUPLICUATED ROWS#
DELETE s1 FROM songs s1
INNER JOIN songs s2
WHERE s1.duplicatecount > s2.duplicatecount AND
s1.song_name = s2.song_name AND
s1.artist_name = s2.artist_name;

ALTER TABLE songs
DROP COLUMN duplicatecount;

select * from songs
order by song_code;

ALTER TABLE songs
ADD COLUMN player_no INT first;

UPDATE songs
set songs.player_no = (
	select players.player_no from players where
    songs.song_code = players.song_code);

ALTER TABLE songs
RENAME player_song;

drop table if exists songs;
CREATE TABLE songs
SELECT
s3.song_code, s3.song_name, s3.artist_name, s3.artist2_name, s3.duplicatecount 
FROM (SELECT song_code, 
           song_name, 
           artist_name,
           artist2_name,
           ROW_NUMBER() OVER(PARTITION BY song_name
           ORDER BY song_code) AS DuplicateCount
FROM songs_2 s2) s3;

WITH CTE(song_code, 
    song_name, 
    artist_name, 
    artist2_name,
    duplicatecount)
AS (SELECT song_code, 
           song_name, 
           artist_name,
           artist2_name,
           ROW_NUMBER() OVER(PARTITION BY song_name
           ORDER BY song_code) AS DuplicateCount
    FROM songs)
DELETE FROM CTE
WHERE DuplicateCount > 1;

ALTER TABLE songs
RENAME songs_2;




UPDATE players p
SET song_code = (
	SELECT ps.song_code 
	from player_song ps
    where p.player_no = ps.player_no);
    
select *
from player_song;

SELECT s.song_code 
from songs s
join player_song p on p.song_code = s.song_code
    where p.song_name = s.song_name and p.artist_name = s.artist_name;

SELECT first_name
from players
where song = "Papa Dios Me Dijo";

UPDATE players
SET first_name = "Enyel"
where player_no = 220;

SELECT count(song_code), artist_name
FROM songs
GROUP BY artist_name
ORDER BY count(song_code) desc;

# * Song Breakdown per Artist
SELECT s3.artist_name, count(s3.song_code) as counts
FROM (
	SELECT song_code, artist_name 
    FROM songs s1
    UNION ALL
    SELECT song_code, artist2_name
    FROM songs s2) as s3
WHERE s3.artist_name <> ""
GROUP BY s3.artist_name
ORDER BY count(s3.song_code) desc;

# * Song Breakdown per league
SELECT *, RANK() OVER(PARTITION BY pt.league ORDER BY counts DESC) as ranking
FROM (
SELECT t.league, ps.song_code, ps.song_name, ps.artist_name, count(ps.song_code) as counts
FROM player_song ps
JOIN players p
	ON ps.player_no = p.player_no
JOIN teams t
	ON p.team_code = t.team_code
GROUP BY ps.song_name, ps.artist_name, t.league
ORDER BY t.league, count(ps.song_code) desc) pt
ORDER BY league;

# * Song Breakdown per division
SELECT *, RANK() OVER(PARTITION BY pt.division ORDER BY counts DESC) as ranking
FROM (
SELECT t.division, ps.song_code, ps.song_name, ps.artist_name, count(ps.song_code) as counts
FROM player_song ps
JOIN players p
	ON ps.player_no = p.player_no
JOIN teams t
	ON p.team_code = t.team_code
GROUP BY ps.song_name, ps.artist_name, t.division
ORDER BY t.division, count(ps.song_code) desc) pt
ORDER BY division;

# WalkUp Song showed the most appearance
SELECT ps1.song_code, ps1.song_name, ps1.artist_name, ps1.counts, ps4.max_counts
FROM (
		SELECT ps.song_code, ps.song_name, ps.artist_name, count(ps.song_code) as counts 
        FROM player_song ps
        GROUP BY ps.song_name, ps.artist_name
        ORDER BY counts desc) as ps1
    JOIN (
		SELECT MAX(ps3.counts) as max_counts
		FROM (SELECT count(ps2.song_code) as counts
			FROM player_song ps2
            GROUP BY ps2.song_name, ps2.artist_name) as ps3) as ps4
WHERE ps1.counts = ps4.max_counts;

SELECT *
FROM songs
where song_name = "I wrote the book";

SELECT *
FROM player_song
where song_name = "I wrote the book";

UPDATE player_song
SET artist_name = "Morgan Wallen"
WHERE song_name = "I wrote the book";

UPDATE players p, player_song ps
SET p.song_code = ps.song_code
WHERE p.player_no = ps.player_no;


DELETE FROM songs
WHERE artist_name = "Morgan Wallan";



