# takes the combined data and processses it in a nested sequence.
# first creates a grouped dataframe based upon the network column
# this is ued to generate the survey record

#the network grouped dataframe is then used to generate the sectiondata frame and records

#then the section dataframe is broken down into the observation records using the 20 metre subsections
# defind by the StartCh, EndCH and Length columns

using CSV, DataFrames

function process_combined_data(combined_df::DataFrame, survey_ID::String)

    # Group by Network
    grouped_df = groupby(combined_df, :Network)

    for survey_gdf in grouped_df
        # Initialize the output Vector for survey records
        survey_records = String[]

        # the survey record format is
        # SURVEY\TYPE,VERSION,NUMBER,NAME,SUBSECT,CWXSPUSED,OFFCWXSPUSED;
        #SURVEY\CVI,235,5,2025-04-29_0914_3_zzz1,,,;
        survey_type = "CVI"
        survey_version = "235"
        survey_number = "5"
        survey_name = survey_ID
        survey_subsect = ""
        cwxsp_used = ""
        off_cwxsp_used = ""

        # Create the survey record
        survey_record = "SURVEY\\" * survey_type *
                                "," *   survey_version *
                                "," * survey_number *
                                "," * survey_name *
                                "," * survey_subsect *
                                "," * cwxsp_used *
                                "," * off_cwxsp_used *
                                ";\n"
        # Convert the survey record to a string
        #println("Creating survey record: ", survey_record)
        push!(survey_records, survey_record)

    # Loop through each group to create survey records

    CSV.write("survey_records.csv", survey_gdf, header=true)

    corrected_survey_df = correct_split_sections(survey_gdf)

    # for row in eachrow(corrected_survey_df)
    # idx = row.original_row  
    # survey_gdf[idx, :] = row[Not(:original_row)]
    # end

    survey_df = DataFrame(survey_gdf)

    # Merge the original survey DataFrame with the corrected one. 
    #This updates the start + end chainage and the length of the subsection.

    df_merged = merge_split_sections(survey_df, corrected_survey_df)

    # # For each column in dataframeB (except the join keys), update dataframeA
    # for col in names(corrected_survey_df)
    #     if col ∉ [:SectionID, :Chainage]
    #         # If the column exists in dataframeA, update it
    #         if col in names(survey_df)
    #             # Use the value from B if present, otherwise keep A's value
    #             survey_df[!, col] = coalesce.(df_merged[!, Symbol(col*"_b")], df_merged[!, Symbol(col*"_a")])
    #         end
    #     end
    # end

    CSV.write("new_survey_records.csv", df_merged, header=true)

    survey_df = DataFrame(df_merged)

    #section_gdf = groupby(survey_gdf, [:SectionID, :Chainage])
    section_gdf = groupby(survey_df, :SectionID)
    #section_number = 0
    for (section_number, section_frame) in enumerate(section_gdf)
        # the only data needed fron the survey level is the network name/number
        network = section_frame.Network[1]  # Get the network name from the first row of the group
        #section_number += 1

        section_df = DataFrame(section_frame)
        # Create a section record for each network
        println("scetion_nunmber : ", section_number)
        section_records = process_section_records(section_df, network, section_number)
        
        for record in section_records
            # println("Adding section record: ", record)
            push!(survey_records, record)
        end
        #push!(survey_records, section_records)
    end

    return survey_records
    end

end