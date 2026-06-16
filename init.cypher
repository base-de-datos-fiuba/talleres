// Restricciones 

CREATE CONSTRAINT worldcup_id IF NOT EXISTS FOR (w:WorldCup) REQUIRE w.tournament_id IS UNIQUE;
CREATE CONSTRAINT team_id IF NOT EXISTS FOR (t:Team) REQUIRE t.team_id IS UNIQUE;
CREATE CONSTRAINT game_id IF NOT EXISTS FOR (g:Game) REQUIRE g.game_id IS UNIQUE;
CREATE CONSTRAINT player_id IF NOT EXISTS FOR (p:Player) REQUIRE p.player_id IS UNIQUE;
CREATE CONSTRAINT stadium_id IF NOT EXISTS FOR (s:Stadium) REQUIRE s.stadium_id IS UNIQUE;

// Creando mundiales

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/jfjelstul/worldcup/refs/heads/master/data-csv/tournaments.csv" AS row
WITH row
WHERE row.tournament_name ENDS WITH "FIFA Men's World Cup"
MERGE (w:WorldCup {tournament_id: row.tournament_id})
SET w.name = row.tournament_name,
    w.year = toInteger(row.year),
    w.start_date = date(row.start_date),
    w.end_date = date(row.end_date),
    w.host_country = row.host_country,
    w.winner = row.winner;

// Creando equipos

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/jfjelstul/worldcup/refs/heads/master/data-csv/teams.csv" AS row
MERGE (t:Team {team_id: row.team_id})
SET t.name = row.team_name,
    t.code = row.team_code,
    t.federation = row.federation_name,
    t.region = row.region_name,
    t.confederation_id = row.confederation_id,
    t.confederation_name = row.confederation_name,
    t.confederation_code = row.confederation_code;


// Creando Estadios

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/jfjelstul/worldcup/refs/heads/master/data-csv/stadiums.csv" AS row
MERGE (s:Stadium {stadium_id: row.stadium_id})
SET s.name = row.stadium_name,
    s.city = row.city_name,
    s.country = row.country_name,
    s.capacity = row.stadium_capacity;

// Creando Jugadores

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/jfjelstul/worldcup/refs/heads/master/data-csv/players.csv" AS row
WITH row
WHERE toInteger(row.female) = 0
MERGE (p:Player {player_id: row.player_id})
SET p.last_name = row.family_name,
    p.first_name = row.given_name,
    p.position = 
        CASE 
            WHEN toInteger(row.goal_keeper) = 1 THEN "Goalkeeper"
            WHEN toInteger(row.defender) = 1 THEN "Defender"
            WHEN toInteger(row.midfielder) = 1 THEN "Midfielder"
            WHEN toInteger(row.forward) = 1 THEN "Forward"
            ELSE "Unknown"
        END,
    p.birth_date = CASE 
        WHEN row.birth_date =~ "\\d{4}-\\d{2}-\\d{2}" THEN date(row.birth_date)
        ELSE null
    END;


// Creando los partidos y las relaciones
//	* (:Team)-[:PARTICIPATES_IN]->(:WorldCup)
//	* (:Game)-[:IS_HOME]->(:Team)
//	* (:Game)-[:IS_AWAY]->(:Team)
//	* (:Game)-[:PLAYED_AT]->(:Stadium)
//	* (:Game)-[:PART_OF]->(:WorldCup)


LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/jfjelstul/worldcup/refs/heads/master/data-csv/matches.csv" AS row
WITH row
WHERE row.tournament_name ENDS WITH "FIFA Men's World Cup"

MERGE (g:Game {game_id: row.match_id})
SET g.name = row.match_name,
    g.date = date(row.match_date),
    g.time = row.match_time,
    g.stage = row.stage_name,
    g.group = row.group_name,
    g.score = row.score,
    g.home_score = toInteger(row.home_team_score),
    g.away_score = toInteger(row.away_team_score),
    g.extra_time = toBoolean(toInteger(row.extra_time)),
    g.penalties = toBoolean(toInteger(row.penalty_shootout)),
    g.home_win = CASE WHEN toInteger(row.home_team_win) = 1 THEN true ELSE false END,
    g.away_win = CASE WHEN toInteger(row.away_team_win) = 1 THEN true ELSE false END,
    g.draw = CASE WHEN toInteger(row.draw) = 1 THEN true ELSE false END

WITH row, g

MATCH (home:Team {team_id: row.home_team_id})
MATCH (away:Team {team_id: row.away_team_id})
MATCH (stadium:Stadium {stadium_id: row.stadium_id})
MATCH (wc:WorldCup {tournament_id: row.tournament_id})

MERGE (home)-[:PARTICIPATES_IN]->(wc)
MERGE (away)-[:PARTICIPATES_IN]->(wc)

MERGE (g)-[:IS_HOME]->(home)
MERGE (g)-[:IS_AWAY]->(away)

MERGE (g)-[:PLAYED_AT]->(stadium)
MERGE (g)-[:PART_OF]->(wc);

// Relación Jugador mete Gol

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/jfjelstul/worldcup/refs/heads/master/data-csv/goals.csv" AS row
WITH row
WHERE row.tournament_name ENDS WITH "FIFA Men's World Cup"

MATCH (p:Player {player_id: row.player_id})
MATCH (g:Game {game_id: row.match_id})

MERGE (p)-[s:SCORED_IN {goal_id: row.goal_id}]->(g)
SET s.minute_regulation = toInteger(row.minute_regulation),
    s.minute_stoppage = toInteger(row.minute_stoppage),
    s.match_period = row.match_period,
    s.own_goal = toBoolean(toInteger(row.own_goal)),
    s.penalty = toBoolean(toInteger(row.penalty));


// Relación Jugador JuegaEn Partido

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/jfjelstul/worldcup/refs/heads/master/data-csv/player_appearances.csv" AS row
WITH row
WHERE row.tournament_name ENDS WITH "FIFA Men's World Cup"

MATCH (p:Player {player_id: row.player_id})
MATCH (g:Game {game_id: row.match_id})
MERGE (team:Team {team_id: row.team_id})
MERGE (p)-[:REPRESENTS]->(team)

MERGE (p)-[r:PLAYED_IN {match_id: row.match_id}]->(g)
SET r.starter = toBoolean(toInteger(row.starter)),
    r.substitute = toBoolean(toInteger(row.substitute)),
    r.shirt_number = toInteger(row.shirt_number),
    r.position = row.position_code,
    r.home_team = toBoolean(toInteger(row.home_team)),
    r.away_team = toBoolean(toInteger(row.away_team)),
    r.team_id = row.team_id;
