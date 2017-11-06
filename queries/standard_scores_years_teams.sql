SELECT match_alliances.id, teams.id as "Team", teams.latitude, teams.longitude, events.year, 
		(score - avg(score) over (PARTITION BY events.year)) / stddev(score) over (PARTITION BY events.year) as "Standard Score"  
        FROM match_alliances
INNER JOIN matches ON matches.id = match_alliances.match_id
INNER JOIN events ON events.id = matches.event_id
INNER JOIN matches_teams ON matches_teams.alliance_id = match_alliances.id
INNER JOIN teams ON teams.id = matches_teams.team_id