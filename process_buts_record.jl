function process_buts_record(start_chainage::Int, end_chainage::Int, observation_number::Int, direction::String)
    observation_number += 1
        #         #observ_defect_record = string("OBSERV\\",frame_number,",BUTS,235,",minimum(section_df.Chainage),",",maximum(section_df.Chainage),";\n")
    observ_defect_record = string("OBSERV\\",observation_number,",BUTS,235,", direction, start_chainage,",",end_chainage,";\n")
    obval_defect_record = string("OBVAL\\1,3,100,P,,;\n")
    return string(observ_defect_record), string(obval_defect_record)
 
end