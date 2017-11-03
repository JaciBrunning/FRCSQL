require 'json'
require 'sqlite3'
require 'sequel'

require_relative 'create_db'

# @db = Sequel.connect("sqlite:///#{Dir.pwd}/frc_db.sqlite")
@db = Sequel.connect('postgres://test:test@localhost/tbadump')
create_db @db

# Models
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

# Helper Funcs

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

def loaddata file
    puts "Loading #{file}.json..."
    ret = File.read("data/#{file}.json").split("\n").map { |x| JSON.parse(x) }
    puts "Loaded!"
    ret
end

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

# Sort modules on dependencies

@modules = { }

def _tvisit membername, allmembers, sorted
    member = @modules[membername]
    return if member[:mark] > 0
    member[:mark] = 1
    member[:deps].each do |dep|
        _tvisit allmembers[dep][:name], allmembers, sorted
    end
    member[:mark] = 2
    sorted << member
end

def toposort
    sorted = []
    while (!(unmarked = @modules.values.select { |x| x[:mark] == 0 }).empty?)
       _tvisit(unmarked.first()[:name], @modules, sorted) 
    end
    sorted
end

def mod sym, dependencies=[], &block
    @modules[sym] = { name: sym, deps: dependencies, action: block, mark: 0 }
end

alias :_puts :puts
def puts str="", indent=1
    _puts "#{"\t" * indent}#{str}"
end

def loadmodules
    Dir["generation_modules/*.rb"].each { |file| require_relative file }

    toposort.each do |x|
        if !ARGV.select { |y| y.include?("all") || y.include?(x[:name].to_s) }.empty? || ARGV.empty?  
            puts "-> Running #{x[:name].to_s}...", 0
            x[:action].call() 
            puts
        end
    end
end



