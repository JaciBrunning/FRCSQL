mod :district_teams, [:districts, :teams] do
    @dts = loaddata "districtTeam"
    puts "Writing District Teams..."
    @db.transaction do
        @dts.each do |dt|
            Team[dt["team"]["name"]].add_district(District[dt["district_key"]["name"]])
        end
    end
    puts "Done!"
    @dts = nil
end