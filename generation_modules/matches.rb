mod :matches, [:events, :teams] do
    puts "Dropping Table..."   
    Match.db.drop_table?(Match.table_name, cascade: true)
    MatchAlliance.db.drop_table?(MatchAlliance.table_name, cascade: true)
    @db.drop_table?(:matches_teams, cascade: true)
    @db.drop_table?(:score_types, cascade: true)
    @db.drop_table?(:match_scores, cascade: true)
    reinit_tables

    puts "Running Native Code"
    system('bash', '-c', 'pushd native; ./matches; popd', out: $stdout, err: :out)

    puts "Done!"
    @matches = nil
end