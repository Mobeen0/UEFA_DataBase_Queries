
-------------------------------------------- TABLE CREATION ---------------------------------------------

CREATE DATABASE Assignment3;
USE Assignment3;


CREATE TABLE TEAMS(
	ID INT NOT NULL PRIMARY KEY,
	TEAM_NAME VARCHAR(255) NOT NULL,
	HOME_STADIUM_ID INT NOT NULL
);

CREATE TABLE CITIES(
	CITY VARCHAR(255) NOT NULL PRIMARY KEY,
	COUNTRY VARCHAR(255) NOT NULL
);

CREATE TABLE STADIUMS(
	ID INT NOT NULL PRIMARY KEY,
	NAME VARCHAR(255) NOT NULL,
	CITY VARCHAR(255) NOT NULL,
	CAPACITY INT NOT NULL
);

CREATE TABLE PLAYERS(
	PLAYER_ID VARCHAR(8) NOT NULL PRIMARY KEY,
	FIRST_NAME VARCHAR(255),
	LAST_NAME VARCHAR(255) NOT NULL,
	NATIONALITY VARCHAR(255) NOT NULL,
	DOB DATE,
	TEAM_ID INT,
	JERSEY_NUMBER INT,
	POSITION VARCHAR(255) NOT NULL,
	HEIGHT INT, 
	WEIGHT INT,
	FOOT CHAR(1),
);

CREATE TABLE STAFF(
	STAFF_ID VARCHAR(7) NOT NULL PRIMARY KEY,
	FIRST_NAME VARCHAR(255),
	LAST_NAME VARCHAR(255) NOT NULL,
	NATIONALITY VARCHAR(255) NOT NULL,
	DOB DATE,
	TEAM_ID INT,
	POSITION VARCHAR(255) NOT NULL,
	HEIGHT INT, 
	WEIGHT INT,
	FOOT CHAR(1)
);

CREATE TABLE MANAGERS(
	ID INT NOT NULL PRIMARY KEY,
	FIRST_NAME VARCHAR(255),
	LAST_NAME VARCHAR(255) NOT NULL,
	NATIONALITY VARCHAR(255) NOT NULL,
	DOB DATE,
	TEAM_ID INT
);


CREATE TABLE MATCHES(
	MATCH_ID VARCHAR(7) NOT NULL PRIMARY KEY,
	SEASON CHAR(9) NOT NULL,
	DATE_TIME VARCHAR(255) NOT NULL,
	HOME_TEAM_ID INT NOT NULL,
	AWAY_TEAM_ID INT NOT NULL,
	HOME_TEAM_SCORE INT NOT NULL,
	AWAY_TEAM_SCORE INT NOT NULL,
	PENALTY_SHOOT_OUT INT NOT NULL,
	ATTENDANCE INT NOT NULL,
);

CREATE TABLE GOALS(
	GOAL_ID VARCHAR(8) NOT NULL PRIMARY KEY,
	MATCH_ID VARCHAR(7) NOT NULL,
	PID VARCHAR(8),
	DURATION INT NOT NULL,
	ASSIST VARCHAR(8),
	GOAL_DESC VARCHAR(255)
);

ALTER TABLE STADIUMS
ADD FOREIGN KEY (CITY) REFERENCES CITIES(CITY);
ALTER TABLE PLAYERS
ADD FOREIGN KEY (TEAM_ID) REFERENCES TEAMS(ID);
ALTER TABLE STAFF
ADD FOREIGN KEY (TEAM_ID) REFERENCES TEAMS(ID);
ALTER TABLE MANAGERS
ADD FOREIGN KEY (TEAM_ID) REFERENCES TEAMS(ID);
ALTER TABLE MATCHES
ADD FOREIGN KEY (AWAY_TEAM_ID) REFERENCES TEAMS(ID);
ALTER TABLE MATCHES
ADD FOREIGN KEY (HOME_TEAM_ID) REFERENCES TEAMS(ID);
ALTER TABLE TEAMS
ADD FOREIGN KEY (HOME_STADIUM_ID) REFERENCES STADIUMS(ID);
ALTER TABLE GOALS
ADD FOREIGN KEY(MATCH_ID) REFERENCES MATCHES(MATCH_ID);
ALTER TABLE GOALS
ADD FOREIGN KEY (PID) REFERENCES PLAYERS(PLAYER_ID);
ALTER TABLE GOALS
ADD FOREIGN KEY (ASSIST) REFERENCES PLAYERS(PLAYER_ID);

-------------------------------------------------------------------------------------------------------


------------------------------------ UTILITY FUNCTIONS AND PROCEDURES ----------------------------------------

GO
CREATE PROCEDURE PlayersUnderManager @fname VARCHAR(255),@lname VARCHAR(255)
AS
BEGIN

SELECT p.PLAYER_ID,CONCAT(p.FIRST_NAME,' ',p.LAST_NAME) AS 'Player Name', p.DOB,p.JERSEY_NUMBER,p.POSITION,p.NATIONALITY
FROM MANAGERS m
INNER JOIN PLAYERS p
ON m.TEAM_ID = p.TEAM_ID
WHERE @fname = m.FIRST_NAME AND @lname = m.LAST_NAME;

END
GO


GO
CREATE PROCEDURE MatchesInCountry @CountryN VARCHAR(255)
AS
BEGIN

SELECT m.MATCH_ID, m.SEASON, m.DATE_TIME AS 'Date', t.TEAM_NAME AS 'Home', t2.TEAM_NAME AS 'Away', m.HOME_TEAM_SCORE , m.AWAY_TEAM_SCORE, m.PENALTY_SHOOT_OUT,c.CITY
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
INNER JOIN TEAMS t2
ON m.AWAY_TEAM_ID = t2.ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = S.ID
INNER JOIN CITIES c
ON S.CITY = c.CITY
WHERE c.COUNTRY = @CountryN;

END
GO


GO
CREATE FUNCTION TotalHomeGames(@Tname VARCHAR(255))
RETURNS INT
AS
BEGIN
RETURN(
SELECT COUNT(*)
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
WHERE t.TEAM_NAME LIKE @Tname
)
END
GO


GO
CREATE FUNCTION GETMAXCOUNTRY()
RETURNS VARCHAR(255)
AS
BEGIN

RETURN(
SELECT TOP 1 c.COUNTRY
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = s.ID
INNER JOIN CITIES c
ON s.CITY = c.CITY
GROUP BY c.COUNTRY
ORDER BY SUM(s.CAPACITY) DESC)
END
GO


GO
CREATE FUNCTION TotalGoalsTogether(@player1 VARCHAR(255),@player2 VARCHAR(255))
RETURNS INT
AS
BEGIN
RETURN(
	(SELECT COUNT(*)
	FROM GOALS g
	WHERE g.PID LIKE @player1 AND g.ASSIST LIKE @player2)
	+
	(SELECT COUNT(*)
	FROM GOALS g
	WHERE g.PID LIKE @player2 AND g.ASSIST LIKE @player1)
)
END
GO


GO
CREATE FUNCTION TotalTeamGoals20(@Tname VARCHAR(255))
RETURNS INT
AS
BEGIN
RETURN(
	SELECT COUNT(*)
	FROM GOALS g
	INNER JOIN PLAYERS p
	ON g.PID = p.PLAYER_ID
	INNER JOIN TEAMS t
	ON p.TEAM_ID = t.ID
	INNER JOIN MATCHES m
	ON g.MATCH_ID = m.MATCH_ID
	WHERE t.TEAM_NAME = @Tname AND SUBSTRING(m.DATE_TIME,8,2) LIKE '20' -- for the year 2020 (IMPORTING ERROR SO COULDNT USE DATA TYPE DATE TIME)
)
END

GO

-----------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------- SQL QUERIES ---------------------------------------------------------


---------------------------------- QUESTION 1 -----------------------------

EXEC PlayersUnderManager @fname = 'Stefano', @lname = 'Pioli'; -- passing the manager name as the argument, this can  be changed to another name

---------------------------------------------------------------------------

---------------------------------- QUESTION 2 -----------------------------

EXEC MatchesInCountry @CountryN = 'Belgium';

---------------------------------------------------------------------------

---------------------------------- QUESTION 3 -----------------------------

SELECT t.ID, t.TEAM_NAME,S.NAME AS 'Stadium',COUNT (m.HOME_TEAM_ID) AS 'WINS'
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = s.ID
WHERE m.HOME_TEAM_SCORE > m.AWAY_TEAM_SCORE
GROUP BY T.ID,t.TEAM_NAME,s.NAME
HAVING COUNT(m.HOME_TEAM_ID) > 3
ORDER BY COUNT(m.HOME_TEAM_ID) DESC;

---------------------------------------------------------------------------

---------------------------------- QUESTION 4 -----------------------------

SELECT t.TEAM_NAME,c.COUNTRY AS 'Team Country',CONCAT(m.FIRST_NAME,' ',m.LAST_NAME) AS 'Manager Name',m.NATIONALITY AS 'Manager Country'
FROM TEAMS t
INNER JOIN STADIUMS s
ON t.Home_Stadium_ID = s.ID
INNER JOIN CITIES c
ON s.CITY = c.CITY
INNER JOIN MANAGERS m
ON m.TEAM_ID=t.ID
WHERE m.NATIONALITY <> c.COUNTRY;

---------------------------------------------------------------------------


---------------------------------- QUESTION 5 -----------------------------

SELECT m.MATCH_ID, m.SEASON, m.DATE_TIME AS 'Date', t.TEAM_NAME AS 'Home Team', t2.TEAM_NAME AS 'Away Team', m.HOME_TEAM_SCORE , m.AWAY_TEAM_SCORE, m.PENALTY_SHOOT_OUT,s.CITY, s.CAPACITY
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
INNER JOIN TEAMS t2
ON m.AWAY_TEAM_ID = t2.ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = s.ID
WHERE s.CAPACITY >60000;

---------------------------------------------------------------------------

---------------------------------- QUESTION 6 -----------------------------

SELECT g.GOAL_ID, CONCAT(p.FIRST_NAME,' ',p.LAST_NAME) AS 'Full Name', CONVERT(DATE,SUBSTRING(m.DATE_TIME,1,9)) AS 'Date' ,p.HEIGHT,g.GOAL_DESC AS 'Description'
FROM MATCHES m
INNER JOIN GOALS g
ON m.MATCH_ID = g.MATCH_ID
INNER JOIN PLAYERS p
ON p.PLAYER_ID= g.PID
WHERE g.ASSIST IS NULL AND p.HEIGHT > 180 AND m.DATE_TIME LIKE '%-20 %'; -- WE WERE GETTING ERROR SO DATE_TIME IS VARCHAR IN OUR SCHEMA

---------------------------------------------------------------------------

---------------------------------- QUESTION 7 -----------------------------

SELECT t.ID,t.TEAM_NAME AS 'TEAM NAME', c.COUNTRY, COUNT(t.ID) AS 'Total Wins' ,dbo.TotalHomeGames(t.TEAM_NAME) AS 'Total Games',(COUNT(t.ID)*100)/(dbo.TotalHomeGames(t.TEAM_NAME)) AS 'Win Percentage'
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = s.ID
INNER JOIN CITIES c
ON c.CITY = s.CITY
WHERE m.HOME_TEAM_SCORE>m.AWAY_TEAM_SCORE AND c.COUNTRY LIKE 'Russia'
GROUP BY t.TEAM_NAME,t.ID,c.COUNTRY
HAVING COUNT(t.ID) < (
	SELECT COUNT(t2.ID)
	FROM MATCHES m2
	INNER JOIN TEAMS t2
	ON m2.HOME_TEAM_ID = t2.ID
	WHERE m2.HOME_TEAM_SCORE <= m2.AWAY_TEAM_SCORE AND m2.HOME_TEAM_ID = t.ID
-- ACCOUNTING FOR DRAWS AS WELL
)
ORDER BY 'Total Games' DESC;

---------------------------------------------------------------------------


---------------------------------- QUESTION 8 -----------------------------

SELECT s.NAME,COUNT(s.NAME) AS 'Home Wins',dbo.TotalHomeGames(t.TEAM_NAME) AS 'Total Home Games', (COUNT(s.NAME)*100/(dbo.TotalHomeGames(t.TEAM_NAME))) AS 'Hosted Wins Percentage'
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = s.ID
WHERE m.HOME_TEAM_SCORE > m.AWAY_TEAM_SCORE -- CALCULATING WINS
GROUP BY s.NAME,t.TEAM_NAME,t.ID
HAVING COUNT (t.ID) < ( 
	SELECT COUNT(t2.ID)
	FROM MATCHES m2
	INNER JOIN TEAMS t2
	ON m2.HOME_TEAM_ID = t2.ID
	WHERE m2.HOME_TEAM_SCORE <= m2.AWAY_TEAM_SCORE AND m2.HOME_TEAM_ID = t.ID
	HAVING (COUNT(t2.ID) + COUNT(t.ID)>6)-- CALCULATING WIN + LOSS + TIES = TOTAL GAMES PLAYED
	) 
ORDER BY 'Hosted Wins Percentage' ASC;

---------------------------------------------------------------------------

---------------------------------- QUESTION 9 -----------------------------

SELECT TOP 1 m.SEASON, COUNT(m.SEASON) AS 'Left Foot Goals'
FROM MATCHES m
INNER JOIN GOALS g
ON m.MATCH_ID = g.MATCH_ID
WHERE g.GOAL_DESC LIKE '%left-foot%'
GROUP BY m.SEASON
ORDER BY COUNT(m.SEASON) DESC;

---------------------------------------------------------------------------


---------------------------------- QUESTION 10 -----------------------------

SELECT TOP 1 p.NATIONALITY AS 'Country', COUNT(g.PID) AS 'Goals',COUNT(DISTINCT(g.PID)) AS 'Unique Players'
FROM GOALS g
INNER JOIN PLAYERS p
ON g.PID = p.PLAYER_ID
GROUP BY p.NATIONALITY
ORDER BY COUNT(DISTINCT(g.PID)) DESC;

---------------------------------------------------------------------------


---------------------------------- QUESTION 11 -----------------------------

SELECT s.NAME,S.CITY,s.CAPACITY,COUNT(g.GOAL_ID) AS 'Left Goals'
FROM GOALS g
INNER JOIN MATCHES m
ON g.MATCH_ID = m.MATCH_ID
INNER JOIN TEAMS t
ON t.ID = m.HOME_TEAM_ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = s.ID
WHERE g.GOAL_DESC LIKE '%left-foot%'
GROUP BY s.NAME,t.ID,S.CITY,s.CAPACITY
HAVING COUNT(g.GOAL_ID) > (
	SELECT COUNT(g2.GOAL_ID)
	FROM GOALS g2
	INNER JOIN MATCHES m2
	ON g2.MATCH_ID = m2.MATCH_ID
	INNER JOIN TEAMS t2
	ON t2.ID = m2.HOME_TEAM_ID
	INNER JOIN STADIUMS s2
	ON t2.HOME_STADIUM_ID = s2.ID
	WHERE g2.GOAL_DESC LIKE '%right-foot%' AND t2.ID = t.ID
)
ORDER BY 'Left Goals' DESC;

---------------------------------------------------------------------------


---------------------------------- QUESTION 12 -----------------------------

SELECT m.MATCH_ID,m.DATE_TIME,t.TEAM_NAME AS 'Home Team', t2.TEAM_NAME AS 'Away Team', m.HOME_TEAM_SCORE,m.AWAY_TEAM_SCORE,s.NAME AS 'Stadium',c.City,m.ATTENDANCE
FROM MATCHES m
INNER JOIN TEAMS t
ON m.HOME_TEAM_ID = t.ID
INNER JOIN TEAMS t2
ON m.AWAY_TEAM_ID = t2.ID
INNER JOIN STADIUMS s
ON t.HOME_STADIUM_ID = s.ID
INNER JOIN CITIES c
ON s.CITY = c.CITY
WHERE c.COUNTRY LIKE dbo.GETMAXCOUNTRY()
ORDER BY CONVERT(DATE,SUBSTRING(m.DATE_TIME,1,9)) DESC;

---------------------------------------------------------------------------


---------------------------------- QUESTION 13 -----------------------------

SELECT TOP 1 CONCAT(p1.FIRST_NAME,' ',P1.LAST_NAME) AS 'Player 1',CONCAT(p2.FIRST_NAME,' ',p2.LAST_NAME) AS 'Player 2',dbo.TotalGoalsTogether(g.PID,g.ASSIST) AS 'Total Goals'
FROM GOALS g
JOIN PLAYERS p1
ON g.PID = p1.PLAYER_ID
JOIN PLAYERS p2
ON G.ASSIST= p2.PLAYER_ID
WHERE g.ASSIST NOT LIKE g.PID
GROUP BY g.PID,g.ASSIST,CONCAT(p1.FIRST_NAME,' ',P1.LAST_NAME),CONCAT(p2.FIRST_NAME,' ',p2.LAST_NAME)
ORDER BY 'Total Goals' DESC; -- QUERY IS NOT EFFICENT AND WILL TAKE ABOUT 4 SECONDS TO RUN <3

---------------------------------------------------------------------------

---------------------------------- QUESTION 14 -----------------------------

SELECT TOP 1 t.Team_NAME,COUNT(*) AS 'Total Head Goals' ,dbo.TotalTeamGoals20(t.TEAM_NAME) AS 'Total Goals',(COUNT(*) *100)/dbo.TotalTeamGoals20(t.TEAM_NAME) AS 'Head Goals Percentage'
FROM GOALS g
INNER JOIN PLAYERS p
ON g.PID = p.PLAYER_ID
INNER JOIN TEAMS t
ON p.TEAM_ID = t.ID
INNER JOIN MATCHES m
ON g.MATCH_ID = m.MATCH_ID
WHERE g.GOAL_DESC LIKE '%header%' AND SUBSTRING(m.DATE_TIME,8,2) LIKE '20'
GROUP BY T.TEAM_NAME
ORDER BY 'Head Goals Percentage' Desc;

---------------------------------------------------------------------------


---------------------------------- QUESTION 15 -----------------------------

SELECT TOP 1 m.ID,CONCAT(m.FIRST_NAME,' ',m.LAST_NAME) AS 'Full Name', t.TEAM_NAME,COUNT(*) AS 'Wins'
FROM MANAGERS m
INNER JOIN TEAMS t
ON m.TEAM_ID = t.ID
INNER JOIN MATCHES mat1
ON (mat1.HOME_TEAM_ID = t.ID OR mat1.AWAY_TEAM_ID = t.ID)
WHERE (t.ID = mat1.HOME_TEAM_ID AND mat1.HOME_TEAM_SCORE > mat1.AWAY_TEAM_SCORE) OR (t.ID = mat1.AWAY_TEAM_ID AND mat1.AWAY_TEAM_SCORE > mat1.HOME_TEAM_SCORE)
GROUP BY m.ID,CONCAT(m.FIRST_NAME,' ',m.LAST_NAME),t.TEAM_NAME -- TEAM CANT HAVE MORE THAN ITSELF AND IT WILL BE EITHER HOME OR AWAY
ORDER BY COUNT(*) DESC; 			     -- SO to count wins it needs to have more than the team it isnt

---------------------------------------------------------------------------
