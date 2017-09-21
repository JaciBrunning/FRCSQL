require 'json'
require 'sqlite3'
require 'sequel'

require_relative 'create_db'

@db = Sequel.connect("sqlite:///#{Dir.pwd}/frc_db.sqlite")
def loaddata file
    puts "Loading #{file}.json..."
    ret = File.read("data/#{file}.json").split("\n").map { |x| JSON.parse(x) }
    puts "Loaded!"
    ret
end

create_db @db

class District < Sequel::Model(@db[:districts])
end

class EventType < Sequel::Model(@db[:event_types])
    unrestrict_primary_key
end

class Event < Sequel::Model(@db[:events])
    many_to_one :district
    many_to_one :parent, class: self
    many_to_one :event_type
    many_to_many :team
end

class Team < Sequel::Model(@db[:teams])
    unrestrict_primary_key
    many_to_many :district
    many_to_many :event
end

class AllianceSelection < Sequel::Model(@db[:alliance_selections])
    many_to_one :event
    many_to_one :team
end

class TeamEventStat < Sequel::Model(@db[:team_event_stats])
    many_to_one :event
    many_to_one :team
end

class Match < Sequel::Model(@db[:matches])
    many_to_one :event
    many_to_one :tiebreaker_match, class: self    
end

class MatchAlliance < Sequel::Model(@db[:match_alliances])
    many_to_one :match
    many_to_many :team, left_key: :alliance_id, join_table: :matches_teams
end

class ScoreType < Sequel::Model(@db[:score_types])
end

class MatchScore < Sequel::Model(@db[:match_scores])
    many_to_one :match
    many_to_one :alliance, class: :MatchAlliance
    many_to_one :type, class: :ScoreType
end

class AwardType < Sequel::Model(@db[:award_types])
end

class Award < Sequel::Model(@db[:awards])
    many_to_one :type, class: :AwardType
    many_to_one :event
    many_to_one :team
end

# myevent = Event.find_or_create(name: "MyEvent", year: 2017)
# myotherevent = Event.find_or_create(name: "MyOtherEvent", year: 2016, parent: myevent)
# team = Team.find_or_create(number: 5333)

# # team.add_event(myevent)
# # myotherevent.add_team(team)

# myselection = AllianceSelection.find_or_create(alliance: 1, picknum: 1, team: team, event: myevent)
# mystat = TeamEventStat.find_or_create(event: myevent, team: team, stat_type: "opr", value: 3.14)

# m1 = Match.find_or_create(event: myevent, match_key: "2017cmptx_f1m1")
# m2 = Match.find_or_create(event: myevent, match_key: "2017cmptx_f1m2")
# m1.tiebreaker_match = m2
# m1.save

# ma = MatchAlliance.find_or_create(match: m1, color: "red")
# # ma.add_team(team)

# st = ScoreType.find_or_create(year: 2017, name: "Fuel High")
# ms = MatchScore.find_or_create(match: m1, alliance: ma, type: st, value: 100)

def write_location obj, model
    if model["normalized_location"].nil?
        obj.country = obj.country_short = model["country"]
        obj.state_prov = obj.state_prov_short = model["state_prov"]
        obj.address = model["venue_address"].nil? ? model["address"] : model["venue_address"]
        obj.city = model["city"]
        obj.postcode = model["postalcode"]
    else
        nl = model["normalized_location"]
        obj.country = nl["country"]
        obj.country_short = nl["country_short"]
        obj.state_prov = nl["state_prov"]
        obj.state_prov_short = nl["state_prov_short"]
        obj.address = nl["formatted_address"]
        obj.city = nl["city"]
        unless nl["lat_lng"].nil?
            obj.latitude = nl["lat_lng"]["lat"]
            obj.longitude = nl["lat_lng"]["long"]
        end
        obj.postcode = nl["postal_code"]
    end
    obj.save
end

@districts = loaddata "district"
puts "Writing District Data..."
@db.transaction do
    @districts.each do |d|
        District.create(key: d["__key__"]["name"], display_name: d["display_name"],
            abbrev: d["abbreviation"], year: d["year"].to_i)
    end
end
puts "Done!"
@districts = nil

EVENTTYPES = {
    0 => "Regional",
    1 => "District",
    2 => "District Championship",
    3 => "Championship Division",
    4 => "Championship Finals",
    5 => "District Championship Divison",
    6 => "Festival of Champions",
    99 => "Offseason",
    100 => "Week 0"
}

@db.transaction do
    EVENTTYPES.each do |key, value|
        EventType.create(id: key, type: value)
    end
end

@events = loaddata "event"
puts "Writing Event Data..."
@db.transaction do
    @events.each do |e|
        event = Event.create(key: e["__key__"]["name"], code: e["event_short"],
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

@teams = loaddata "team"
puts "Writing Team Data..."
@db.transaction do
    @teams.each do |t|
        team = Team.create(key: t["__key__"]["name"], number: t["team_number"],
            nickname: t["nickname"], name: t["name"], motto: t["motto"],
            school_name: t["school_name"], website: t["website"], rookie_year: t["rookie_year"],
            home_championship: t["home_cmp"])
        write_location team, t
    end
end
puts "Done!"
@teams = nil

@dts = loaddata "districtTeam"
puts "Writing District Teams..."
@db.transaction do
    @dts.each do |dt|
        Team.first(key: dt["team"]["name"]).add_district(District.first(key: dt["district_key"]["name"]))
    end
end
puts "Done!"
@dts = nil

@ets = loaddata "eventTeam"
puts "Writing Event Teams..."
@db.transaction do
    @ets.each do |et|
        Team.first(key: et["team"]["name"]).add_event(Event.first(key: et["event"]["name"]))
    end
end
puts "Done!"
@ets = nil

