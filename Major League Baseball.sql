-- sean_lahman_baseball_db

-- Connect to database
USE maven_advanced_sql;

SHOW TABLES;

-- PART I: SCHOOL ANALYSIS


-- 1. View the schools and school details tables
SELECT *
FROM schools;

SELECT *
FROM school_details;


-- 2. In each decade, how many schools were there that produced players?
SELECT * 
FROM schools;

SELECT yearID, schoolID 
FROM schools;

-- decade = FLOOR(year/10)*10  -> 1990 - 1999 = 1 decade (10 yrs)
SELECT FLOOR(yearID/10)*10 AS decade, COUNT(DISTINCT schoolID) AS num_schools
FROM schools
GROUP BY decade
ORDER BY decade;


-- 3. What are the names of the top 5 schools that produced the most players?

-- Step 1
SELECT sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
FROM schools s LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
GROUP BY s.schoolID
ORDER BY num_players DESC;

-- --------------------------------------------------------------------------
-- Step 2
SELECT sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
FROM schools s LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
GROUP BY s.schoolID
ORDER BY num_players DESC 
LIMIT 5;


-- 4. For each decade, what were the names of the top 3 schools that produced the most players?

-- Step 1
SELECT FLOOR(yearID/10)*10 AS decade, sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
            FROM schools s LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
            GROUP BY decade, s.schoolID
            ORDER BY decade, num_players DESC;

-- Step 2
            WITH ds AS (SELECT FLOOR(yearID/10)*10 AS decade, sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
            FROM schools s LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
            GROUP BY decade, s.schoolID
            ORDER BY decade, num_players DESC)

            SELECT *, ROW_NUMBER() OVER(PARTITION BY decade ORDER BY num_players DESC) AS row_num
            FROM ds;
-- ----------------------------------------------------------------------------------------------------------------------------            
-- Step 3
WITH ds AS (SELECT FLOOR(yearID/10)*10 AS decade, sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
            FROM schools s LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
            GROUP BY decade, s.schoolID
            ORDER BY decade, num_players DESC),

     rn AS (SELECT decade, name_full, num_players, ROW_NUMBER() OVER(PARTITION BY decade ORDER BY num_players DESC) AS row_num
            FROM ds)
            
SELECT * FROM rn WHERE row_num <= 3;


/* -------------------------------------------------------------------------------------------------------
LEARNED :
3 ---> functional dependency
Logic: Since schoolID (primary key) determines name_full (it's functionally dependent),
the database doesn't need you to group by name_full to know which name to display.
(any non-aggregated column in the SELECT clause must be included in the GROUP BY clause NOT vice versa)

4 ---> order of execution matters
cte->from/join->where->groupby->having->window fn->select->distinct->orderby->limit/offset
SELECT *, ROW_NUMBER() OVER(PARTITION BY decade ORDER BY num_players DESC) AS row_num
FROM ds
WHERE row_num <= 3; -- WRONG -> WHERE runs before window function
------------------------------------------------------------------------------------------------------------*/



-- PART II: SALARY ANALYSIS


-- 1. View the salaries table

SELECT * FROM salaries;
SELECT * FROM SALARIES WHERE YEARID = 1985 AND TEAMID = "CAL" ORDER BY YEARID;

-- 2. Return the top 20% of teams in terms of average annual spending

-- Step 1 - annual spending
WITH team_annual_avg AS (SELECT yearID, teamID, SUM(salary) AS annual_spend 
             FROM salaries
			 GROUP BY teamID,yearID
			 ORDER BY teamID,  yearID)
             
-- Step 2 - avg of all year spending for each team
SELECT teamID, AVG(annual_spend) AS avg_spend
FROM team_annual_avg
GROUP BY teamID
ORDER BY teamID;
-- ----------------------------------------------------------------------------------------- 
-- *Step 3 - TOP 20% of teams in terms of average annual spending - NTILE() window fn - desc 
WITH team_annual_avg AS (SELECT yearID, teamID, SUM(salary) AS annual_spend 
             FROM salaries
			 GROUP BY teamID,yearID
			 ORDER BY teamID,  yearID),
             
	 top_twenty AS (SELECT teamID, AVG(annual_spend) AS avg_spend,
                  NTILE(5) OVER (ORDER BY AVG(annual_spend) DESC) AS percentile
                  FROM team_annual_avg
                  GROUP BY teamID)
                  
-- Step 4 - only top 20% as output (IN millions to 1 decimal place)
SELECT teamID, ROUND(avg_spend / 1000000, 1) AS avg_spend_millions FROM top_twenty WHERE percentile = 1;



-- 3. For each team, show the cumulative sum of spending over the years

-- Step 1 - spending over the years for each team 
SELECT teamID, yearID, SUM(salary) AS annual_spent
FROM salaries
GROUP BY teamID, yearID
ORDER BY teamID, yearID;
 
-- ----------------------------------------------------------------------------------------------
-- Step 2 - cum sum round to nearest Million           
WITH cum_sum AS (SELECT teamID, yearID, SUM(salary) AS annual_spent
             FROM salaries
			 GROUP BY teamID, yearID
			 ORDER BY teamID, yearID)

SELECT teamID, yearID, ROUND(annual_spent / 1000000, 1) AS annual_spent_millions,
ROUND(SUM(annual_spent) OVER(PARTITION BY teamID ORDER BY yearID) / 1000000, 1) AS cum_sum_millions
FROM cum_sum;


-- 4. Return the first year that each team's cumulative spending surpassed 1 billion

WITH cum_sum AS (SELECT teamID, yearID, SUM(salary) AS annual_spent
             FROM salaries
			 GROUP BY teamID, yearID
			 ORDER BY teamID, yearID),

	 above AS (SELECT teamID, yearID, annual_spent,
               ROUND(SUM(annual_spent) OVER(PARTITION BY teamID ORDER BY yearID) / 1000000000, 2) AS cum_sum_billions
               FROM cum_sum),

year_filter AS (SELECT teamID, yearID, cum_sum_billions,
				ROW_NUMBER() OVER (PARTITION BY teamID ORDER BY cum_sum_billions) AS surpass
                FROM above
                WHERE cum_sum_billions > 1)

SELECT teamID, yearID, cum_sum_billions
FROM year_filter
WHERE surpass = 1;

/* -------------------------------------------------------------------------------------------------------
LEARNED :
2 ---> GROUP BY
A group by clause just defines the unique combination of field(s) which would be considered a group.
There is no meaning to the order these fields are stated.


2 ---> order of execution matters 
SELECT executes after OVER()

------------------------------------------------------------------------------------------------------------*/





-- PART III: PLAYER CAREER ANALYSIS

-- 1. View the players table and find the number of players in the table
SELECT * FROM players;

SELECT COUNT(DISTINCT playerID) FROM players; -- 18589



-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.

-- Step 1 - birth date
SELECT nameGiven, birthYear, birthMonth, birthDay, debut, finalGame,
       CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS birthDate
FROM players;

-- Step 2 - age at their first game

-- METHOD 1 - without CAST, DATEDIFF
WITH birth_date AS (SELECT nameGiven, birthYear, birthMonth, birthDay, debut, finalGame,
                    CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS birthDate
                    FROM players)
SELECT nameGiven, debut, birthDate, ROUND (DATEDIFF(debut, birthDate) / 365, 0) AS debutAge
FROM birth_date;  


-- METHOD 2 - with CAST, DATEDIFF

WITH birth_date AS (SELECT nameGiven, birthYear, birthMonth, birthDay, debut, finalGame,
                    CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthDate
                    FROM players)
SELECT nameGiven, debut, birthDate, ROUND (DATEDIFF(debut, birthDate) / 365, 0) AS debutAge
FROM birth_date;                
                

-- METHOD 3 - with TIMESTAMPDIFF
SELECT nameGiven, debut, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthDate,
TIMESTAMPDIFF (YEAR, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE), debut) AS debutAge
FROM players; 


-- Step 3 - age at last game & carrer length

SELECT nameGiven, debut, finalGame,
CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthDate,
TIMESTAMPDIFF (YEAR, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE), debut) AS debutAge,
TIMESTAMPDIFF (YEAR, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE), finalGame) AS endAge,
TIMESTAMPDIFF (YEAR, debut, finalGame) AS careerLength
FROM players;

-- Step 4 sort : longest career to shortest
SELECT CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthDate,
TIMESTAMPDIFF (YEAR, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE), debut) AS debutAge,
TIMESTAMPDIFF (YEAR, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE), finalGame) AS endAge,
TIMESTAMPDIFF (YEAR, debut, finalGame) AS careerLength
FROM players
ORDER BY careerLength DESC; -- SELECT clause executes before



-- 3. What team did each player play on for their starting and ending years?
SELECT * FROM players;
SELECT * FROM salaries;

-- Step 1 - join tables to fetch info
SELECT p.playerID, p.nameGiven, p.debut, p.finalGame, s.yearID, s.teamID, e.yearID, e.teamID
FROM players p INNER JOIN salaries s ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID -- start year
               INNER JOIN salaries e ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID; -- end year

-- Step 2 - clean data for relevant info
SELECT p.nameGiven, s.yearID AS start_year, s.teamID AS start_team, e.yearID AS end_year, e.teamID AS end_team
FROM players p INNER JOIN salaries s ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID 
               INNER JOIN salaries e ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID; 



-- 4. How many players started and ended on the same team and also played for over a decade?
SELECT p.nameGiven, s.yearID AS start_year, s.teamID AS start_team, e.yearID AS end_year, e.teamID AS end_team
FROM players p INNER JOIN salaries s ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID 
               INNER JOIN salaries e ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID
WHERE s.teamID = e.teamID AND e.yearID - s.yearID = 10; 



/* -------------------------------------------------------------------------------------------------------
LEARNED :
2 ---> 
CONCAT(value1, value2, value3, ...)
CAST(expression AS datatype)
DATEDIFF(date1, date2) - date1 - date2 (in days)
TIMESTAMPDIFF(unit, start_date, end_date) - units :YEAR, MONTH, DAY, HOUR, MINUTE
(complete date with year month day required, NOT integers)


2 ---> alias 
SQL does not allow using a column alias in the same SELECT clause where it is created.

2---> extract units
eg. year unit - YEAR(complete_date)

------------------------------------------------------------------------------------------------------------*/




-- PART IV: PLAYER COMPARISON ANALYSIS

-- 1. View the players table
SELECT * FROM players;


-- 2. Which players have the same birthday?

-- METHOD 1 : Basic

-- SELECT playerID, nameGiven, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthDate
-- FROM players
-- WHERE birthYear IS NOT NULL AND birthMonth IS NOT NULL AND birthDay IS NOT NULL;

WITH birthName AS (SELECT playerID, nameGiven, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthDate
				   FROM players
				   WHERE birthYear IS NOT NULL AND birthMonth IS NOT NULL AND birthDay IS NOT NULL),
                   -- WHERE executes before SELECT
                   
-- SELECT birthDate, COUNT(*)
-- FROM birthName
-- GROUP BY birthDate
-- HAVING COUNT(*) > 1;

	 same_birthdays AS (SELECT birthDate, COUNT(*) AS count
                        FROM birthName
                        GROUP BY birthDate
                        HAVING COUNT(*) > 1)

SELECT b.birthDate, b.nameGiven
FROM birthName b INNER JOIN same_birthdays s
ON b.birthDate = s.birthDate
ORDER BY b.birthDate, b.nameGiven;


-- METHOD 2 : group concat - gem to eyes :)

WITH bn AS (SELECT CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthDate, nameGiven
            FROM players)
            
SELECT birthDate, GROUP_CONCAT(nameGiven SEPARATOR ' ,') AS players, COUNT(nameGiven) AS count 
FROM bn
WHERE birthdate IS NOT NULL
GROUP BY birthDate
HAVING count > 1
ORDER BY birthDate;            



-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both

-- Step 1 - check
SELECT * FROM players;
SELECT DISTINCT(bats) FROM players; -- R, L, B, NULL
SELECT * FROM salaries;

-- Step 2 - filter info
SELECT playerID, bats
FROM players; -- bat info

SELECT playerID, teamID
FROM salaries; -- team info

SELECT s.teamID, s.playerID, p.bats
FROM salaries s LEFT JOIN players p
     ON s.playerID = p.playerID;

-- Step - fetch R, L, B data - *pivot column - p.bats
SELECT s.teamID, s.playerID,
       CASE WHEN p.bats = 'R' THEN 1 ELSE 0 END AS R_bats, -- right
       CASE WHEN p.bats = 'L' THEN 1 ELSE 0 END AS L_bats, -- left 
       CASE WHEN p.bats = 'B' THEN 1 ELSE 0 END AS B_bats -- both
FROM salaries s LEFT JOIN players p
ON s.playerID = p.playerID;

-- Step 4 - agg by team
SELECT s.teamID, COUNT(s.playerID) AS total_players,
       SUM(CASE WHEN p.bats = 'R' THEN 1 ELSE 0 END) AS R_bats, -- right
       SUM(CASE WHEN p.bats = 'L' THEN 1 ELSE 0 END) AS L_bats, -- left 
       SUM(CASE WHEN p.bats = 'B' THEN 1 ELSE 0 END) AS B_bats -- both
FROM salaries s LEFT JOIN players p
ON s.playerID = p.playerID
GROUP BY s.teamID;

-- Step 5 - find % - total_R_bats / total_players
SELECT s.teamID, COUNT(s.playerID) AS total_players,
       ROUND(SUM(CASE WHEN p.bats = 'R' THEN 1 ELSE 0 END) / COUNT(s.playerID)*100, 1) AS R_bats_cent, -- right
       ROUND(SUM(CASE WHEN p.bats = 'L' THEN 1 ELSE 0 END) / COUNT(s.playerID)*100, 1) AS L_bats_cent, -- left 
       ROUND(SUM(CASE WHEN p.bats = 'B' THEN 1 ELSE 0 END) / COUNT(s.playerID)*100, 1) AS B_bats_cent -- both
FROM salaries s LEFT JOIN players p
ON s.playerID = p.playerID
GROUP BY s.teamID;


-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?
-- STEP 1 - check info
SELECT * FROM players;

SELECT playerID, debut, height, weight
FROM players;

-- Step 2 - debut year
SELECT playerID, YEAR(debut) AS debut_yr, height, weight
FROM players;

-- Step 3 - decade over decade - 10 yrs
SELECT playerID, ROUND(YEAR(debut), -1) AS debut_yr, height, weight
FROM players;

-- Step 4 - avg height, weight in each decade
SELECT ROUND(YEAR(debut), -1) AS decade, AVG(height) AS avg_ht, AVG(weight) AS avg_wt
FROM players
GROUP BY decade
HAVING decade IS NOT NULL -- remove -ve val
ORDER BY decade;

-- Step 5 - prev decade avg height & avg weight - window fn
WITH decade_record AS (SELECT ROUND(YEAR(debut), -1) AS decade, AVG(height) AS avg_ht, AVG(weight) AS avg_wt
                       FROM players
                       GROUP BY decade
                       ORDER BY decade)

SELECT decade, avg_ht, avg_wt,
	   LAG(avg_ht) OVER(ORDER BY decade) AS prev_ht,
       LAG(avg_wt) OVER(ORDER BY decade) AS prev_wt 
FROM decade_record;	

-- Step 6 - change : decade over decade diff : (curr_decade - prev_decade = diff)

WITH decade_record AS (SELECT ROUND(YEAR(debut), -1) AS decade, AVG(height) AS avg_ht, AVG(weight) AS avg_wt
                       FROM players
                       GROUP BY decade)
                       

SELECT decade,
	   ROUND(avg_ht - (LAG(avg_ht) OVER(ORDER BY decade)), 1) AS ht_diff,
       ROUND(avg_wt - (LAG(avg_wt) OVER(ORDER BY decade)), 1) AS wt_diff
FROM decade_record
WHERE decade IS NOT NULL;	-- remove -ve val


				
/* -------------------------------------------------------------------------------------------------------
LEARNED :
2 ---> 
GROUP_CONCAT(row_name ORDER BY row_name SEPARATOR ',') 
function to combine multiple rows into one field, typically with a comma separator by default

3---> alias remainder
alias created in SELECT clause can't be used in the same SELECT clause

3 ---> *CONDITIONAL AGGREGATION or pivoting
condition of using a CASE statement with SUM() 
------------------------------------------------------------------------------------------------------------*/

