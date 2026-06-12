--1. Listing all students, who play for a particular department (i.e. Cohort 4 group).
SELECT 
    p.player_name,
    g.group_name
FROM Player p
JOIN "group" g ON p.group_id = g.group_id   --joining the group table to the player table using the primary/foreign key group_id
WHERE g.group_name = 'Cohort 4';

/*2. Listing all fixtures for a specific date (i.e. 29th of October 2022 and including 
team names and venues).*/
SELECT 
    m.match_id,
    s.match_date,
    t1.team_name AS home_team,
    t2.team_name AS away_team,
    v.venue_name
FROM Match m
--joining teams, schedule and venue on match by the primary/foreign key relating the 2 tables together.
JOIN Schedule s ON m.schedule_id = s.schedule_id
JOIN Team t1 ON m.home_team_id = t1.team_id
JOIN Team t2 ON m.away_team_id = t2.team_id
JOIN Venue v ON m.venue_id = v.venue_id
WHERE s.match_date = '2022-10-29';

--3. Listing all the players who have scored more than 2 goals
SELECT 
    p.player_name,
    COUNT(*) AS goals_scored  --counts goals scored
FROM Player p
/*joining match event on player and event type on match event
we can now see which player did what event*/
JOIN Match_Event me ON p.player_id = me.player_id
JOIN Event_Type et ON me.event_type_id = et.event_type_id
WHERE et.event_type = 'Goal'  --selects the event type goals
GROUP BY p.player_name
HAVING COUNT(*) > 2;

--4. Listing the number of cards (yellow and red) per team.
SELECT 
    t.team_name,
    COUNT(*) AS total_cards  --counts total number of cards
FROM Team t
/*joining player on team, match event on player, event type on match event
allows us to see which players got cards and which team they play for*/
JOIN Player p ON t.team_id = p.team_id
JOIN Match_Event me ON p.player_id = me.player_id
JOIN Event_Type et ON me.event_type_id = et.event_type_id
WHERE et.event_type IN ('Yellow Card', 'Red Card')  --selects all cards
GROUP BY t.team_name
ORDER BY total_cards DESC;

--5. Return the games that are going to be played (friendly matches).
SELECT 
    m.match_id,
    s.match_date,
    t1.team_name AS home_team,
    t2.team_name AS away_team
FROM Match m
/*joining competition, schedule and team onto match allows us to 
see which matches, when they are played and who is playing
for all the friendly games*/
JOIN Competition c ON m.competition_id = c.competition_id
JOIN Schedule s ON m.schedule_id = s.schedule_id
JOIN Team t1 ON m.home_team_id = t1.team_id
JOIN Team t2 ON m.away_team_id = t2.team_id
WHERE c.competition_type = 'Friendly';  --selects only the friendly games

/*6. The table displays the team's name and the points earned during the 
tournament.*/
WITH goals AS (
    SELECT 
        m.match_id,
        m.home_team_id,
        m.away_team_id,

		--finds the score of each game
        SUM(CASE 
            WHEN p.team_id = m.home_team_id THEN 1 ELSE 0 
        END) AS home_goals,
        
        SUM(CASE 
            WHEN p.team_id = m.away_team_id THEN 1 ELSE 0 
        END) AS away_goals
        
    FROM Match m
    JOIN Match_Event me ON m.match_id = me.match_id
    JOIN Player p ON me.player_id = p.player_id
    JOIN Event_Type et ON me.event_type_id = et.event_type_id
    WHERE et.event_type = 'Goal'
    GROUP BY m.match_id, m.home_team_id, m.away_team_id
),

--calculates points based on which team has more goals or if they have the same goals
points AS (
    SELECT 
        home_team_id AS team_id,
        CASE 
            WHEN home_goals > away_goals THEN 3
            WHEN home_goals = away_goals THEN 1
            ELSE 0
        END AS pts
    FROM goals

    UNION ALL

    SELECT 
        away_team_id AS team_id,
        CASE 
            WHEN away_goals > home_goals THEN 3
            WHEN away_goals = home_goals THEN 1
            ELSE 0
        END AS pts
    FROM goals
)

SELECT 
    t.team_name,
    SUM(p.pts) AS total_points
FROM points p
JOIN Team t ON p.team_id = t.team_id
GROUP BY t.team_name
ORDER BY total_points DESC;

/*7. For each team, present the distribution of goals scored and conceded in each 
half of the match.*/
SELECT 
    t.team_name,

    -- Adds together the goals scored in the first half 
    SUM(CASE 
        WHEN p.team_id = t.team_id --when team_id is the same for the event and the player it means the goal is scored by that team
        AND me.minute <= 45 THEN 1 ELSE 0 --minute<=45 means its in the first half
    END) AS goals_scored_1st_half,

    -- Adds together the goals scored in the second half
    SUM(CASE 
        WHEN p.team_id = t.team_id --when team_id is the same for the event and the player it means the goal is scored by that team
        AND me.minute > 45 THEN 1 ELSE 0 --minute>45 means its in the second half
    END) AS goals_scored_2nd_half,

    -- Goals conceded (1st half)
    SUM(CASE 
        WHEN p.team_id != t.team_id --when team_id is not the same for the event and the player it means the goal is conceded by that team
        AND me.minute <= 45 THEN 1 ELSE 0 --minute<=45 means its in the first half
    END) AS goals_conceded_1st_half,

    -- Goals conceded (2nd half)
    SUM(CASE 
        WHEN p.team_id != t.team_id --when team_id is not the same for the event and the player it means the goal is conceded by that team
        AND me.minute > 45 THEN 1 ELSE 0 --minute>45 means its in the second half
    END) AS goals_conceded_2nd_half

--Joining together tables that allow us to use team_id to see if the goal is scored or conceded
FROM Team t
JOIN Match m ON t.team_id IN (m.home_team_id, m.away_team_id)
JOIN Match_Event me ON m.match_id = me.match_id
JOIN Player p ON me.player_id = p.player_id
JOIN Event_Type et ON me.event_type_id = et.event_type_id

WHERE et.event_type = 'Goal'

GROUP BY t.team_name;
