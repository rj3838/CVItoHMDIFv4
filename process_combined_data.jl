# takes the combined data and processses it in a nested sequence.
# first creates a grouped dataframe based upon the network column
# this is ued to generate the survey record

#the network grouped dataframe is then used to generate the sectiondata frame and records

#then the section dataframe is broken down into the observation records using the 20 metre subsections
# defind by the StartCh, EndCH and Length columns

using CSV, DataFrames

function process_combined_data(combined_df::DataFrame, survey_ID::String, hmd_section_count::Integer)
    println("Processing combined data for survey ID: $survey_ID")
    # Group by Network
    grouped_df = DataFrames.groupby(combined_df, :Network)

    for survey_gdf in grouped_df
        # Initialize the output Vector for survey records
        survey_records = String[]

        # # the survey record format is
        # # SURVEY\TYPE,VERSION,NUMBER,NAME,SUBSECT,CWXSPUSED,OFFCWXSPUSED;
        # #SURVEY\CVI,235,5,2025-04-29_0914_3_zzz1,,,;
        # survey_type = "CVI"
        # survey_version = "235"
        # survey_number = "5"
        # survey_name = survey_ID
        # survey_subsect = ""
        # cwxsp_used = ""
        # off_cwxsp_used = ""

        # # Create the survey record
        # survey_record = "SURVEY\\" * survey_type *
        #                         "," *   survey_version *
        #                         "," * survey_number *
        #                         "," * survey_name *
        #                         "," * survey_subsect *
        #                         "," * cwxsp_used *
        #                         "," * off_cwxsp_used *
        #                         ";\n"
        # # Convert the survey record to a string
        # #println("Creating survey record: ", survey_record)
        # push!(survey_records, survey_record)

        # Loop through each group to create survey records

        #CSV.write("survey_records.csv", survey_gdf, header=true)

        #corrected_survey_df = correct_split_sections(survey_gdf)

    # for row in eachrow(corrected_survey_df)
    # idx = row.original_row  
    # survey_gdf[idx, :] = row[Not(:original_row)]
    # end
        
        survey_df = DataFrame(survey_gdf)

    # Merge the original survey DataFrame with the corrected one. 
    #This updates the start + end chainage and the length of the subsection.

    #df_merged = merge_split_sections(survey_df, corrected_survey_df)

    #CSV.write("new_survey_records.csv", df_merged, header=true)
        total_section_record_count = 0

        survey_df = DataFrame(combined_df)

    #section_gdf = groupby(survey_gdf, [:SectionID, :Chainage])
        section_gdf = DataFrames.groupby(survey_df, :SectionID)
        
        for (section_number, section_frame) in enumerate(section_gdf)
            # the only data needed fron the survey level is the network name/number
            network = section_frame.Network[1]  # Get the network name from the first row of the group

            section_df = DataFrame(section_frame)
            # Create a section record for each network
            println("scetion_nunmber : ", section_number)
            println("total_section_record_count : ",total_section_record_count)
            # so the section_record_count continues to increment add the cruuent section to 
            # the total count passed in to the function
            total_section_record_count = hmd_section_count + section_number
            section_records = process_section_records(section_df, network, total_section_record_count, survey_ID)
            #println("Section records: ", section_records)
            #println(typeof(section_records))
            
            for record in section_records
                # println("Adding section record: ", record)
                # convert to string and append a newline
                record = string(record)
                push!(survey_records, record)
            #push!(survey_records, section_records)
            end
            
        end

    filter!(!isempty, survey_records)

    #hmdif_count = size(survey_records)[1]
    #println("process test ", lastindex(survey_records))

    #println("hmdif_count = ", hmdif_count)

    # hmd_records = vcat(hmd_records)
    #hmd_single_vector = Iterators.flatten(survey_records)

    #hmd_collected = collect(hmd_single_vector)

    #hmdif_count = size(hmd_collected)[1]
    #println("hmdif_count after flatten = ", hmdif_count)
    #filter!(!isempty, hmd_collected)
    #println("process test count pcd ", lastindex(hmd_collected))

    #hmdif_count = lastindex(hmd_collected)
    println("finished processing survey ID: $survey_ID with ", length(survey_records), " records")
    return survey_records, total_section_record_count
    end
end
#return hmd_collected