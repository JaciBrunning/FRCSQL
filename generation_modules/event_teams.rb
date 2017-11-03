mod :event_teams, [:teams, :events] do
    @ets = loaddata "eventTeam"
    puts "Writing Event Teams... (This may take a while)"
    @db.transaction do
        @ets.each do |et|
            Team.first(key: et["team"]["name"]).add_event(Event.first(key: et["event"]["name"]))
        end
    end
    puts "Done!"
    @ets = nil
end