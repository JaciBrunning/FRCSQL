def create_db db
    db.create_table? :districts do
        primary_key :id
        String :key, null: :false, unique: true, collate: :nocase
        String :display_name, null: false, collate: :nocase
        String :abbrev, null: false, collate: :nocase
        Integer :year, null: false
    end

    db.create_table? :event_types do
        primary_key :id
        String :type, collate: :nocase
    end

    db.create_table? :events do
        primary_key :id
        foreign_key :parent_id, :events, null: true, on_delete: :set_null       # Optional: Parent Event (i.e. championships and divisions)
        foreign_key :district_id, :districts, null: true, on_delete: :set_null  # Optional: District for the Event
        String :key, null: false, unique: true, collate: :nocase
        String :code, collate: :nocase
        foreign_key :event_type_id, :event_types, on_delete: :cascade
        String :name
        String :short_name, collate: :nocase
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
        primary_key :number, null: false, unique: true
        String :key, null: false, unique: true, collate: :nocase
        String :home_championship
        String :nickname, collate: :nocase
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
        foreign_key :district_id, :districts, on_delete: :cascade
        foreign_key :team_id, :teams, on_delete: :cascade
        primary_key [:district_id, :team_id]
    end

    db.create_table? :events_teams do
        foreign_key :event_id, :events, on_delete: :cascade
        foreign_key :team_id, :teams, on_delete: :cascade
        primary_key [:event_id, :team_id]
    end

    db.create_table? :alliance_selections do
        primary_key :id
        foreign_key :event_id, :events, on_delete: :cascade
        foreign_key :team_id, :teams, on_delete: :cascade
        Integer :alliance
        Integer :picknum
        unique [:event_id, :team_id, :alliance]
    end

    db.create_table? :team_event_stats do
        primary_key :id
        foreign_key :event_id, :events, on_delete: :cascade
        foreign_key :team_id, :teams, on_delete: :cascade
        String :stat_type
        Float :value
        unique [:event_id, :team_id, :stat_type]
    end

    db.create_table? :matches do
        primary_key :id
        foreign_key :event_id, :events, on_delete: :cascade
        foreign_key :tiebreaker_match_id, :matches, null: true, on_delete: :set_null  # Optional: Tiebreaker Match

        String :match_key
        String :comp_level
        Integer :match_num
        Integer :set_num

        DateTime :scheduled_time
        DateTime :predicted_time
        DateTime :actual_time
        DateTime :results_time
    end

    db.create_table? :match_alliances do
        primary_key :id
        foreign_key :match_id, :matches, on_delete: :cascade
        String :color
        unique [:match_id, :color]
    end

    db.create_table? :matches_teams do
        foreign_key :team_id, :teams, on_delete: :cascade
        foreign_key :alliance_id, :match_alliances, on_delete: :cascade
        primary_key [:team_id, :alliance_id]
    end

    db.create_table? :score_types do
        primary_key :id
        Integer :year
        String :name
        unique [:year, :name]
    end

    db.create_table? :match_scores do
        primary_key :id
        foreign_key :match_id, :matches, on_delete: :cascade
        foreign_key :alliance_id, :match_alliances, on_delete: :cascade
        foreign_key :type_id, :score_types, on_delete: :cascade
        Integer :value
        unique [:match_id, :alliance_id, :type_id]
    end

    db.create_table? :award_types do
        primary_key :id
        String :name
    end

    db.create_table? :awards do
        primary_key :id
        foreign_key :type_id, :award_types, on_delete: :cascade
        foreign_key :event_id, :events, on_delete: :cascade
        foreign_key :team_id, :teams, null: true, on_delete: :cascade
        String :awardee
        unique [:type_id, :event_id, :awardee, :team_id]
    end

    # TODO: District Points
    # @db.create_table? :district_points

    # end

    # TODO: Rankings with year-specific schema
    # @db.create_table? :rankings

    # end
end