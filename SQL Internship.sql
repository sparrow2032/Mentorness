create database game_analysis;

use game_analysis;

select * from level_details2 ;
select * from  player_details;

select distinct(count(P_id)) from player_details;

-- Q1  Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.

select l.P_ID, l.Dev_id,p.pname, l.Difficulty from level_details2 as l
join player_details as P on l.P_ID = P.P_id
where level = 0;

-- Q2 Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed.

select p.L1_code, avg(l.Kill_count)  from player_details as p
join level_details2 as l on p.P_ID = l.P_id
where l.lives_earned = 2 and l.stages_crossed >=3
group by p.l1_code;

/**Q3 Find the total number of stages crossed at each difficulty level for Level 2 with players
	  using `zm_series` devices. Arrange the result in decreasing order of the total number of
	  stages crossed.**/

select difficulty,count(stages_crossed) as Total from level_details2
where level = 2 and Dev_Id like 'zm%%' 
group by difficulty
order by Total desc;

/** Q4 Extract `P_ID` and the total number of unique dates for those players who have played
	   games on multiple days.**/

select p.p_id,  count(distinct( l.TimeStamp)) as Total from player_details as p
join level_details2 as l on p.P_ID = l.P_id
group by P.P_id
having Total>1;

/** Q5 Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the
	   average kill count for Medium difficulty.**/

select p_id, difficulty,sum(kill_count) as total from level_details2
where kill_count > (select avg(kill_count) as average from level_details2 where difficulty = "Medium")
group by P_id,difficulty;

/** Q6 Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. 
	   Arrange in ascending order of level.**/

select l.level,p.L1_code, sum(l.lives_earned) as Total 
from level_details2 as l 
join player_details as p on l.P_id = p.P_id
where l.level <>0
group by l.level,p.l1_code
order by level asc;

/** Q7 Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using
	   `Row_Number`. Display the difficulty as well.**/
with demo as (
select Dev_id,difficulty, score ,
row_number() over (partition by dev_id order by score desc) as Rank_ 
from level_details2)
select Dev_id,difficulty,score,Rank_ from demo
where rank_<=3;
	
-- Q8 Find the `first_login` datetime for each device ID.

with first_login as(
select * , row_number() over (partition by dev_id order by timestamp) as Rank_ from level_details2)
select dev_id,timestamp from first_login
where Rank_ = 1;


/** Q9 Find the top 5 scores based on each difficulty level and rank them in increasing order
using `Rank`. Display `Dev_ID` as well. **/

with Top_5 as(
select Dev_id,difficulty, score ,
rank() over (partition by difficulty order by score desc) as Rank_ 
from level_details2 )
select Dev_id,difficulty,score,Rank_ from Top_5
where rank_<=5;

/** Q10 Find the device ID that is first logged in (based on `start_datetime`) for each player
	    (`P_ID`). Output should contain player ID, device ID, and first login datetime. **/

with first_login as(
select * , row_number() over (partition by p_id order by timestamp) as Rank_ from level_details2)
select p_id,dev_id,timestamp from first_login
where Rank_ = 1;

/** Q11 For each player and date, determine how many `kill_counts` were played by the player
		so far.
a) Using window functions **/

select p_id, day(timestamp)as date_ , sum(kill_count) over(partition by p_id  order by timestamp ) as total_kills
from level_details2;


UPDATE level_details2
SET timestamp = STR_TO_DATE(timestamp, '%d-%m-%Y %H:%i');

-- b) Without window functions

select a.p_id, day(a.timestamp) as date_, sum(b.kill_count) as total_kills
from level_details2 as a join level_details2 as b
on a.p_id = b.p_id
where a.timestamp >= b.timestamp
group by a.p_id, a.timestamp
order by a.p_id;

/** Q12 Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`,
		the most recent `start_datetime`. **/
select p_id,timestamp,stages_crossed,sum(stages_crossed)
over(partition by p_id order by timestamp rows between unbounded preceding and current row) as cummulative_sum 
from level_details2;


-- Q13 Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

WITH top_3 AS (
SELECT Dev_ID, P_ID,SUM(score) AS total_score,
ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(score) DESC) AS ranked
FROM level_details2
GROUP BY Dev_ID,P_ID)
SELECT Dev_ID,P_ID,total_score
FROM top_3
WHERE ranked <= 3;


/** Q14 Find players who scored more than 50% of the average score, scored by the sum of
scores for each `P_ID`. **/

SELECT P_ID, TotalScore
FROM (SELECT P_ID, SUM(Score) AS TotalScore FROM level_details2
GROUP BY P_ID) AS PlayerScores
WHERE TotalScore > ( SELECT AVG(TotalScore) * 0.5 FROM ( SELECT SUM(Score) AS TotalScore
FROM level_details2
GROUP BY P_ID) AS AvgScore
);


/** Q15 Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID`
		and rank them in increasing order using `Row_Number`. Display the difficulty as well. **/

DELIMITER //
CREATE PROCEDURE heatshotcount(IN n INT)
BEGIN
SELECT Dev_ID, p_ID, headshots_count, difficulty
FROM (SELECT Dev_ID, p_ID, headshots_count, difficulty,
ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY headshots_count DESC) AS Rank_
FROM level_details2) AS RankedHeadshots
WHERE Rank_ <= n;
END //
DELIMITER ;

call heatshotcount(3)   -- Replace 3 with the desired value of n


