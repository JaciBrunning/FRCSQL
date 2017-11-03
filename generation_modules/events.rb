mod :events, [:districts] do
    puts "Dropping existing values..."
    Event.dataset.destroy
    EventType.dataset.destroy

    @db.transaction do
        EVENTTYPES.each do |key, value|
            EventType.find_or_create(id: key, type: value)
        end
    end

    @events = loaddata "event"
    puts "Writing Event Data..."
    @db.transaction do
        @events.each do |e|
            event = Event.find_or_create(key: e["__key__"]["name"], code: e["event_short"],
                event_type: EventType[e["event_type_enum"]], name: e["name"],
                short_name: e["short_name"], official: e["official"],
                website: e["website"], playoff_type: e["playoff_type"],
                year: e["year"], start_date: e["start_date"], end_date: e["end_date"] )
            write_location event, e
            unless e["district_key"].nil? || e["district_key"]["name"].nil?
                event.district = District.first(key: e["district_key"]["name"])
                event.save
            end

            # TODO: Alliance Selections, Event Stats
        end
    end
    puts "Solving Event Dependencies..."
    @db.transaction do
        @events.each do |e|
            unless e["parent_event"].nil? || e["parent_event"]["name"].nil?
                event = Event.first(key: e["__key__"]["name"])
                event.parent = Event.first(key: e["parent_event"]["name"])
                event.save
            end
        end
    end
    puts "Done!"
    @events = nil
end