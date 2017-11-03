mod :districts do
    puts "Dropping existing values..."    
    District.dataset.destroy

    @districts = loaddata "district"
    puts "Writing District Data..."
    @db.transaction do
        @districts.each do |d|
            District.find_or_create(key: d["__key__"]["name"], display_name: d["display_name"],
                abbrev: d["abbreviation"], year: d["year"].to_i)
        end
    end
    puts "Done!"
    @districts = nil
end