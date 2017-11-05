mod :teams do
    puts "Dropping existing values..."
    Team.dataset.destroy

    @teams = loaddata "team"
    puts "Writing Team Data..."
    @db.transaction do
        @teams.each do |t|
            team = Team.find_or_create(id: t["__key__"]["name"], number: t["team_number"],
                nickname: t["nickname"], name: t["name"], motto: t["motto"],
                school_name: t["school_name"], website: t["website"], rookie_year: t["rookie_year"],
                home_championship: t["home_cmp"])
            write_location team, t
        end
    end
    puts "Done!"
    @teams = nil
end