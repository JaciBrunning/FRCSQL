#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>
#include <functional>
#include <map>
#include <pqxx/pqxx>

#include "rapidjson/document.h"

using namespace rapidjson;

const std::string DELIM = ",";
#define STR(x) (std::string(x.GetString()))
#define STR_OR_NULL(d, i) ( !d.HasMember(i) ? "null" : d[i].IsNull() ? "null" : std::string(d[i].GetString()) )


int main() {
    std::ifstream ifs("../data/match.json");
    std::string line;
    Document d, score_breakdown, alliances;

    std::map<std::string, int> breakdown_map;
    int breakdown_index = 0;

    int i = 0;

    pqxx::connection C("postgres://test:test@localhost/tbadump");
    pqxx::work *W = new pqxx::work(C);

    C.prepare("match", "INSERT INTO matches (id, event_id, comp_level, match_num, set_num, scheduled_time, predicted_time, actual_time, results_time) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) ON CONFLICT DO NOTHING");
    C.prepare("match_tiebreakers", "UPDATE matches SET tiebreaker_match_id = $1 WHERE id = $2");
    C.prepare("alliance", "INSERT INTO match_alliances (id, match_id, color, score) VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING");
    C.prepare("score_lookup", "INSERT INTO score_types (id, name) VALUES ($1, $2) ON CONFLICT DO NOTHING");
    C.prepare("score", "INSERT INTO match_scores (alliance_id, type_id, value_str, value_num, value_bool) VALUES ($1, $2, $3, $4, $5) ON CONFLICT DO NOTHING");

    printf("Matches + Alliances + Scores\n");
    while(std::getline(ifs, line)) {
        d.Parse(line.data());
        bool has_breakdown = d.HasMember("score_breakdown_json");
        if (has_breakdown) score_breakdown.Parse(d["score_breakdown_json"].GetString());
        alliances.Parse(d["alliances_json"].GetString());

        std::string match_key = (STR(d["__key__"]["name"]));

        std::string sched_time = STR_OR_NULL(d, "time"), 
                    predict_time = STR_OR_NULL(d, "predicted_time"), 
                    act_time = STR_OR_NULL(d, "actual_time"), 
                    res_time = STR_OR_NULL(d, "post_result_time");

        W->prepared("match")
            (match_key)
            (STR(d["event"]["name"]))
            (STR_OR_NULL(d, "comp_level"))
            (STR_OR_NULL(d, "match_number"))
            (STR_OR_NULL(d, "set_number"))
            (sched_time, sched_time != "null")
            (predict_time, predict_time != "null")
            (act_time, act_time != "null")
            (res_time, res_time != "null").exec();

        for (auto it = alliances.MemberBegin(); it != alliances.MemberEnd(); it++) {
            std::string key = STR(it->name);
            Value &teams = (it->value)["teams"];
            Value &score_key = it->value["score"];
            double score = (score_key.IsNumber() ? score_key.GetDouble() : 0);
            std::string alliance = key.substr(0, 1);
            std::string fullkey = match_key + "_" + alliance;
            W->prepared("alliance")(fullkey)(match_key)(alliance)(score).exec();
            for (SizeType i = 0; i < teams.Size(); i++) {
                Value &team = teams[i];
            }
        }

        if (has_breakdown) {
            for (auto it = score_breakdown.MemberBegin(); it != score_breakdown.MemberEnd(); it++) {
                std::string alliance = STR(it->name);
                Value &alliance_score = it->value;
                std::string alliancekey = match_key + "_" + alliance[0];
    
                if (alliance_score.IsObject()) {
                    for (auto itt = alliance_score.MemberBegin(); itt != alliance_score.MemberEnd(); itt++) {
                        std::string score_element = STR(itt->name);
                        Value &score_value = itt->value;
    
                        int score_index;
                        if (breakdown_map.count(score_element)) {
                            score_index = breakdown_map[score_element];
                        } else {
                            score_index = breakdown_index++;
                            breakdown_map[score_element] = score_index;
                            W->prepared("score_lookup")(score_index)(score_element).exec();
                        }
    
                        std::string stringval; bool stringval_null;
                        double numval; bool numval_null;
                        bool boolval; bool boolval_null;
                        if (score_value.IsString()) {
                            stringval = score_value.GetString();
                            stringval_null = false;
                        } else if (score_value.IsNull()) {
                            stringval_null = true;
                        }
    
                        if (score_value.IsNumber()) {
                            numval = score_value.GetDouble();
                            numval_null = false;
                        } else {
                            numval_null = true;
                        }

                        if (score_value.IsBool()) {
                            boolval = score_value.GetBool();
                            boolval_null = false;
                        } else {
                            boolval_null = true;
                        }

                        W->prepared("score")(alliancekey)(score_index)(stringval, !stringval_null)(numval, !numval_null)(boolval, !boolval_null).exec();
                    }
                }
            }
        }

        i++;
        if (i % 1000 == 0) printf("%d\n", i);
        if (i % 5000 == 0) {
            printf("-> Commit\n");
            W->commit();
            delete W;
            W = new pqxx::work(C);
        }
    }
    printf("-> Commit\n");
    W->commit();
    delete W;
    W = new pqxx::work(C);
    
    printf("Tiebreakers...\n");
    // Tiebreakers I have to do here (requires table be populated)...
    ifs.clear();
    ifs.seekg(0);
    while(std::getline(ifs, line)) {
        d.Parse(line.data());
        std::string match_key = (STR(d["__key__"]["name"]));
        std::string tiebreak_match_id = (d.HasMember("tiebreak_match_key") ? STR(d["tiebreak_match_key"]["name"]) : "null");

        if (tiebreak_match_id != "null") {
            W->prepared("match_tiebreakers")(tiebreak_match_id)(match_key).exec();
        }
    }
    printf("-> Commit\n");
    W->commit();
    delete W;
}