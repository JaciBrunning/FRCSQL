SELECT match_alliances.id, score, events.year, 
		(score - avg(score) over (PARTITION BY events.year)) / stddev(score) over (PARTITION BY events.year) as "Standard Score"  
        FROM match_alliances
INNER JOIN matches ON matches.id = match_alliances.match_id
INNER JOIN events ON events.id = matches.event_id