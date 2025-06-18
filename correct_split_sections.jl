using DataFrames
using CSV   

function correct_split_sections(survey_records_df)

    df = survey_records_df 

    #CSV.read("survey_records.csv", DataFrame)

    # Ensure columns are Float64 for comparison
    df.Length = Float64.(df.Length)
    df.StartCh = Float64.(df.StartCh)
    df.EndCh = Float64.(df.EndCh)

    # add a column with the original row number in
    df = insertcols(df, 1, :OriginalRow => 1:nrow(df))

    # # Shifted columns for previous and next comparisons
    # prev_EndCh = [missing; df.EndCh[1:end-1]]
    # next_StartCh = [df.StartCh[2:end]; missing]

    # find the row where length is not 20.0
    filtered_df = df[df.Length .!= 20.0, :]

    # remove rows where the end chainage is equal to the section lemgth as they 
    # are truncated due to being at the end of the section.

    second_filter_df = filtered_df[filtered_df.SECTION_LE .!= filtered_df.EndCh, :]

    gdf = groupby(second_filter_df, :SectionID)

    #println(gdf)

    for sdf in gdf
        if unique(sdf.Length) != 1 && sum(unique(sdf.Length)) == 20.0
            #println("SectionID: ", first(sdf.SectionID), " has unique Lengths summing to 20.0")
            # update the rows with the corrected EndCh
            sdf.StartCh .= sdf.StartCh[1]
            sdf.EndCh .= sdf.EndCh[end]
            sdf.Length .= 20.0

            #println(sdf)
        end
    end

    # reassemble the gdf to a full dataframe
        
    return_df = DataFrame(gdf)


    # Find SectionIDs where the sum of unique Lengths is 20
    # section_ids = [first(g.SectionID) for g in gdf if ((length(unique(g.Length)) != 1)
    #                                                     && (sum(unique(g.Length)) == 20.0))]

    # # Get the OriginalRow values for those SectionIDs
    # result = df[in.(df.SectionID, Ref(section_ids)), :OriginalRow]

    # # Print the result
    # #print the lowest OriginalRow for each SectionID
    # original_row_min = minimum(result)
    # println("Lowest OriginalRow for each SectionID: ", original_row_min) 

    # original_row_max = maximum(result)
    # println("Highest OriginalRow for each SectionID: ", original_row_max)

    # #println(result)

    # #third_filter_df = second_filter_df[second_filter_df.SECTION_LE .!= second_filter_df.StartCh, :]

    # #CSV.write("corrected_survey_records.csv", result, header=true)
    CSV.write("corrected_survey_records.csv", return_df, header=true)

    return return_df

end