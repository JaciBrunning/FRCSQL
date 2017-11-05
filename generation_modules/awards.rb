mod :awards, [:teams, :events] do
    puts "Dropping existing values..."    
    AwardType.dataset.destroy
    Award.dataset.destroy

    @awards = loaddata "award"
    puts "Writing Awards... (This may take a while)"
    @db.transaction do
        @awards.each do |a|
            type = AwardType.find_or_create(name: a["name_str"])
            recip_list = a["recipient_json_list"].map { |x| JSON.parse(x)}
            recip_list.each do |recip|
                aw = Award.new(type: type, event: Event[a["event"]["name"]],
                    awardee: recip["awardee"])
                aw.team = Team[ "frc#{recip["team_number"]}" ] unless recip["team_number"].nil?
                aw.save
            end
        end
    end
    puts "Done!"
    @awards = nil
end