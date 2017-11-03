#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>
#include <functional>
#include <map>

#include "rapidjson/document.h"

using namespace rapidjson;

const std::string DELIM = ",";
#define STR(x) (std::string(x.GetString()))
#define STR_OR_NULL(d, i) ( !d.HasMember(i) ? "null" : d[i].IsNull() ? "null" : std::string(d[i].GetString()) )

typedef std::function<void(Document &, void *)> processfunc;

struct MatchExtra {
    std::ofstream *matches;
    std::ofstream *match_teams;
    std::ofstream *match_scores;
    std::ofstream *match_score_lookup;
    std::map<std::string, int> *scoring_elements_map;
    int scoring_element_index;
};

void _process_match(Document &d, void *extra) {
    struct MatchExtra *mex = (MatchExtra *)extra;
    Document score_breakdown, alliances;
    bool has_breakdown = d.HasMember("score_breakdown_json");
    if (has_breakdown) score_breakdown.Parse(d["score_breakdown_json"].GetString());
    alliances.Parse(d["alliances_json"].GetString());

    std::stringstream match_csv;
    std::stringstream match_teams_csv;
    std::stringstream match_score_csv;

    std::string match_key = (STR(d["__key__"]["name"]));

    match_csv << match_key << DELIM;
    match_csv << (STR(d["event"]["name"])) << DELIM;
    if (d.HasMember("tiebreak_match_key"))
        match_csv << (STR(d["tiebreak_match_key"]["name"])) << DELIM;
    else
        match_csv << ("null") << DELIM;
    match_csv << (STR_OR_NULL(d, "comp_level")) << DELIM;
    match_csv << (STR_OR_NULL(d, "match_number")) << DELIM;
    match_csv << (STR_OR_NULL(d, "set_number")) << DELIM;
    match_csv << (STR_OR_NULL(d, "time")) << DELIM;
    match_csv << (STR_OR_NULL(d, "predicted_time")) << DELIM;
    match_csv << (STR_OR_NULL(d, "actual_time")) << DELIM;
    match_csv << (STR_OR_NULL(d, "post_result_time")) << "\n";

    *(mex->matches) << (match_csv.str());

    for (auto it = alliances.MemberBegin(); it != alliances.MemberEnd(); it++) {
        std::string key = STR(it->name);
        Value &teams = (it->value)["teams"];
        match_teams_csv << match_key << DELIM;
        match_teams_csv << key;
        for (SizeType i = 0; i < teams.Size(); i++) {
            Value &team = teams[i];
            match_teams_csv << DELIM << STR(team);
        }
        match_teams_csv << "\n";
    }
    *(mex->match_teams) << (match_teams_csv.str());

    if (has_breakdown) {
        for (auto it = score_breakdown.MemberBegin(); it != score_breakdown.MemberEnd(); it++) {
            std::string alliance = STR(it->name);
            Value &alliance_score = it->value;

            if (alliance_score.IsObject()) {
                for (auto itt = alliance_score.MemberBegin(); itt != alliance_score.MemberEnd(); itt++) {
                    std::string score_element = STR(itt->name);
                    Value &score_value = itt->value;

                    int score_index;
                    if (mex->scoring_elements_map->count(score_element)) {
                        score_index = (*(mex->scoring_elements_map))[score_element];
                    } else {
                        score_index = mex->scoring_element_index++;
                        (*(mex->scoring_elements_map))[score_element] = score_index;
                        (*(mex->match_score_lookup)) << score_index << DELIM << score_element << "\n";
                    }

                    match_score_csv << match_key << DELIM;
                    match_score_csv << alliance << DELIM;
                    match_score_csv << score_index << DELIM;

                    if (score_value.IsString()) {
                        match_score_csv << STR(score_value) << "\n";
                    } else if (score_value.IsNumber()) {
                        match_score_csv << score_value.GetDouble() << "\n";
                    } else if (score_value.IsBool()) {
                        match_score_csv << (score_value.GetBool() ? "true" : "false") << "\n";
                    } else if (score_value.IsNull()) {
                        match_score_csv << "null" << "\n";
                    } else {
                        printf("%d\n", score_value.GetType());
                        assert(false);      // Kill me
                    }
                }
            }
        }
        *(mex->match_scores) << (match_score_csv.str());
    }

}

void load(std::string file, processfunc cb, void *extra) {
    std::ifstream ifs(file);
    std::string line;
    Document d;

    while(std::getline(ifs, line)) {
        d.Parse(line.data());
        cb(d, extra);
    }
}

int main() {
    std::ofstream matches("out/matches.csv");
    std::ofstream match_teams("out/match_teams.csv");
    std::ofstream match_scores("out/match_scores.csv");
    std::ofstream match_scores_lookup("out/match_scores_lookup.csv");    
    std::map<std::string, int> scoring;
    struct MatchExtra match_streams = { &matches, &match_teams, &match_scores, &match_scores_lookup, &scoring, 0 };

    load("../data/match.json", _process_match, &match_streams);

    return 0;
}