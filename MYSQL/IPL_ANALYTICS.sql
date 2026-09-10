USE ipl_tactics_db;

SELECT 
    batter,
    latency_bucket,
    COUNT(id) AS total_balls,
    SUM(batsman_runs) AS total_runs,
    ROUND((SUM(batsman_runs) * 100.0) / COUNT(id), 2) AS strike_rate,
    ROUND((SUM(is_dot) * 100.0) / COUNT(id), 2) AS dot_ball_pct,
    ROUND((SUM(is_boundary) * 100.0) / COUNT(id), 2) AS boundary_pct
FROM deliveries
WHERE batter_balls_faced <= 20 
GROUP BY batter, latency_bucket
HAVING total_balls >= 200      
ORDER BY batter, latency_bucket DESC;
SELECT 
    d.match_phase,
    d.batter,
    d.bowler,
    COUNT(d.id) AS balls_faced,
    SUM(d.batsman_runs) AS runs_scored,
    SUM(d.is_wicket) AS dismissals,
    ROUND((SUM(d.batsman_runs) * 100.0) / COUNT(d.id), 2) AS strike_rate,
    ROUND((SUM(d.is_dot) * 100.0) / COUNT(d.id), 2) AS dot_pct
FROM deliveries d
GROUP BY d.match_phase, d.batter, d.bowler
HAVING balls_faced >= 25
ORDER BY d.batter, strike_rate ASC;
SELECT 
    v.cluster_id,
    d.batter,
    COUNT(d.id) AS balls_faced,
    SUM(d.batsman_runs) AS runs_scored,
    ROUND((SUM(d.batsman_runs) * 100.0) / COUNT(d.id), 2) AS cluster_strike_rate,
    ROUND((SUM(d.is_dot) * 100.0) / COUNT(d.id), 2) AS cluster_dot_pct
FROM deliveries d
JOIN matches m ON d.match_id = m.match_id
JOIN venue_archetypes v ON m.venue = v.venue
WHERE d.match_phase = 'Middle' -- Overs 7-15 where pitch behavior dictates control
GROUP BY v.cluster_id, d.batter
HAVING balls_faced >= 100
ORDER BY cluster_strike_rate DESC;
SHOW VARIABLES LIKE 'secure_file_priv';

USE ipl_tactics_db;

SELECT 'matches' AS table_name, COUNT(*) AS row_count FROM matches
UNION ALL
SELECT 'venue_archetypes', COUNT(*) FROM venue_archetypes
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries;
USE ipl_tactics_db;

-- View 1: Batter Latency Profiling (Cold Start vs Set)
CREATE OR REPLACE VIEW view_batter_latency AS
SELECT 
    batter,
    latency_bucket,
    COUNT(id) AS balls_faced,
    SUM(batsman_runs) AS runs_scored,
    ROUND((SUM(batsman_runs) * 100.0) / COUNT(id), 2) AS strike_rate,
    ROUND((SUM(is_dot) * 100.0) / COUNT(id), 2) AS dot_pct,
    ROUND((SUM(is_boundary) * 100.0) / COUNT(id), 2) AS boundary_pct
FROM deliveries
WHERE batter_balls_faced <= 20
GROUP BY batter, latency_bucket
HAVING balls_faced >= 200;

-- View 2: Phase-Specific Matchup Profiles
CREATE OR REPLACE VIEW view_matchup_leverage AS
SELECT 
    d.match_phase,
    d.batter,
    d.bowler,
    COUNT(d.id) AS balls_faced,
    SUM(d.batsman_runs) AS runs_scored,
    SUM(d.is_wicket) AS dismissals,
    ROUND((SUM(d.batsman_runs) * 100.0) / COUNT(d.id), 2) AS strike_rate,
    ROUND((SUM(d.is_dot) * 100.0) / COUNT(d.id), 2) AS dot_pct,
    ROUND((SUM(d.is_boundary) * 100.0) / COUNT(d.id), 2) AS boundary_pct
FROM deliveries d
GROUP BY d.match_phase, d.batter, d.bowler
HAVING balls_faced >= 25;

-- View 3: Venue Pitch Archetype Performance
CREATE OR REPLACE VIEW view_venue_archetype_impact AS
SELECT 
    v.cluster_id,
    v.run_rate AS cluster_avg_rr,
    v.boundary_pct AS cluster_avg_boundary_pct,
    d.batter,
    COUNT(d.id) AS balls_faced,
    SUM(d.batsman_runs) AS runs_scored,
    ROUND((SUM(d.batsman_runs) * 100.0) / COUNT(d.id), 2) AS cluster_strike_rate,
    ROUND((SUM(d.is_dot) * 100.0) / COUNT(d.id), 2) AS cluster_dot_pct
FROM deliveries d
JOIN matches m ON d.match_id = m.match_id
JOIN venue_archetypes v ON m.venue = v.venue
WHERE d.match_phase = 'Middle'
GROUP BY v.cluster_id, v.run_rate, v.boundary_pct, d.batter
HAVING balls_faced >= 100;
SELECT * FROM view_batter_latency 
ORDER BY strike_rate DESC 
LIMIT 20;
USE ipl_tactics_db;
SELECT * FROM view_batter_startup_tax LIMIT 15;