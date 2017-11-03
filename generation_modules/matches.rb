mod :matches, [:events, :teams] do
    puts "Can't drop existing values (takes too long). Just delete the DB file."   

    @matches = File.read('preprocess/out/matches.csv').split("\n").map { |x| x.split(",") }
    # puts "Writing Matches... (This may take a while)"
    # print "\t"
    # @db.transaction do
    #     @matches.each_with_index do |m, i|
    #         match = Match.new(event: Event.first(key: m[1]), match_key: m[0], 
    #                     comp_level: m[3], match_num: m[4], set_num: m[5])
    #         match.scheduled_time    = m[6] unless m[6] == "null"
    #         match.predicted_time    = m[7] unless m[7] == "null"
    #         match.actual_time       = m[8] unless m[8] == "null"
    #         match.results_time      = m[9] unless m[9] == "null"
    #         match.save
    #         print "." if i % 100 == 0
    #     end
    # end
    # puts
    puts "Solving Match Tiebreaker Dependencies..."
    @db.transaction do
        @matches.each_with_index do |m, i|
            unless m[2] == "null"
                match = Match.first(match_key: m[0])
                match.tiebreaker_match = Match.first(match_key: m[2])
                match.save
            end
        end
    end
    @matches = File.read('preprocess/out/match_teams.csv').split("\n").map { |x| x.split(",") }
    puts "Writing Match Alliances and Teams... (This may take a while)"
    print "\t"
    @db.transaction do
        @matches.each_with_index do |m, i|
            alliance = MatchAlliance.create(match: Match.first(match_key: m[0]), color: m[1][0])
            [2, 3, 4].each do |i|
                t = Team.first(key: m[i])
                unless (t.nil?)
                    alliance.add_team(t)
                end
            end

            alliance.save
            print "." if i % 100 == 0
        end
    end


    puts "Done!"
    @matches = nil


end