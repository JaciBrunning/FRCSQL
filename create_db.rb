def create_db db
    db.create_table? :districts do
        primary_key :id, type: String
        String :display_name, null: false
        String :abbrev, null: false
        Integer :year, null: false
    end

    db.create_table? :event_types do
        primary_key :id
        String :type
    end

    db.create_table? :events do
        primary_key :id, type: String
        foreign_key :parent_id, :events, type: String, null: true, on_delete: :set_null       # Optional: Parent Event (i.e. championships and divisions)
        foreign_key :district_id, :districts, type: String, null: true, on_delete: :set_null  # Optional: District for the Event
        String :code
        foreign_key :event_type_id, :event_types, on_delete: :cascade
        String :name
        String :short_name
        Boolean :official
        String :website
        Integer :playoff_type
        Integer :year, null: false

        DateTime :start_date
        DateTime :end_date

        String :country
        String :country_short
        String :state_prov
        String :state_prov_short
        String :address
        String :city
        Float :latitude
        Float :longitude
        String :postcode
    end

    db.create_table? :teams do
        primary_key :id, type: String
        Int :number
        String :home_championship
        String :nickname
        String :name
        String :motto
        String :school_name
        String :website
        Integer :rookie_year

        String :country
        String :country_short
        String :state_prov
        String :state_prov_short
        String :address
        String :city
        Float :latitude
        Float :longitude
        String :postcode
    end

    db.create_table? :districts_teams do
        foreign_key :district_id, :districts, type: String, on_delete: :cascade
        foreign_key :team_id, :teams, type: String, on_delete: :cascade
        primary_key [:district_id, :team_id]
    end

    db.create_table? :events_teams do
        foreign_key :event_id, :events, type: String, on_delete: :cascade
        foreign_key :team_id, :teams, type: String, on_delete: :cascade
        primary_key [:event_id, :team_id]  
    end

    db.create_table? :alliance_selections do
        foreign_key :event_id, :events, type: String, on_delete: :cascade
        foreign_key :team_id, :teams, type: String, on_delete: :cascade
        Integer :alliance
        Integer :picknum
        primary_key [:event_id, :team_id, :alliance]
    end

    db.create_table? :team_event_stats do
        foreign_key :event_id, :events, type: String, on_delete: :cascade
        foreign_key :team_id, :teams, type: String, on_delete: :cascade
        String :stat_type
        Float :value
        primary_key [:event_id, :team_id, :stat_type]
    end

    db.create_table? :matches do
        primary_key :id, type: String        
        foreign_key :event_id, :events, type: String, on_delete: :cascade
        foreign_key :tiebreaker_match_id, :matches, type: String, null: true, on_delete: :set_null  # Optional: Tiebreaker Match

        String :comp_level
        Integer :match_num
        Integer :set_num

        DateTime :scheduled_time
        DateTime :predicted_time
        DateTime :actual_time
        DateTime :results_time
    end

    db.create_table? :match_alliances do
        primary_key :id, type: String
        foreign_key :match_id, :matches, type: String, on_delete: :cascade, deferrable: true
        String :color
        Float :score
        unique [:match_id, :color]
    end

    db.create_table? :matches_teams do
        # We don't use a team FK here since some teams that compete in offseason events aren't official teams
        foreign_key :team_id, type: String
        foreign_key :alliance_id, :match_alliances, type: String, on_delete: :cascade, deferrable: true
        primary_key [:team_id, :alliance_id]
    end

    db.create_table? :score_types do
        primary_key :id
        String :name, unique: true
    end

    db.create_table? :match_scores do
        foreign_key :alliance_id, :match_alliances, type: String, on_delete: :cascade, deferrable: true
        foreign_key :type_id, :score_types, on_delete: :cascade, deferrable: true
        String :value_str, null: true
        Float :value_num, null: true
        Boolean :value_bool, null: true
        primary_key [:alliance_id, :type_id]
    end

    db.create_table? :award_types do
        primary_key :id
        String :name
    end

    db.create_table? :awards do
        primary_key :id
        foreign_key :type_id, :award_types, on_delete: :cascade
        foreign_key :event_id, :events, type: String, on_delete: :cascade
        foreign_key :team_id, :teams, type: String, null: true, on_delete: :cascade
        String :awardee
        unique [:type_id, :event_id, :awardee, :team_id]
    end

    # TODO: District Points
    # @db.create_table? :district_points

    # end

    # TODO: Rankings with year-specific schema
    # @db.create_table? :rankings

    # end

    # TODO: Match Stats
    # @db.create_table? :oprs
    # end
end