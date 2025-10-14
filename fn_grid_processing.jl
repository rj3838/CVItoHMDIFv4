function fn_grid_processing(grid_file_name::String, section_df::DataFrame)
    # this is designed to process a single grid file.   
    #println("in function name:", grid_file_name)
    grid_df = read_data_grid(grid_file_name)

    # change the filetype to be csv and read the route file

    route_file_name = string(replace(grid_file_name, ".grd" => ".csv"))

    #println("route file name ", route_file_name)

    route_df = open_route_file(route_file_name)

    # remove the rows that have missing or empty values 
    # this gets rid of the bottom block of data in the grd file
    dropmissing!(route_df)
    dropmissing!(grid_df)

    #println("writing debug files")
    #CSV.write("debug_route.csv", route_df)
    #CSV.write("debug_grid.csv", grid_df)
    
    # take the three data frames and merge/join them to produce a single dataframe 
    # that can be processed by survey, section and observation.
    #println(names(grid_df))

    combined_df  = build_main_df(grid_df, route_df, section_df)
    #CSV.write("debug_combined.csv", combined_df)

    #All the needed data is now in the combined_df

    #create the survey name and survey file name
    survey_output_file, survey_ID = create_survey_name(grid_file_name)
    #println("survey name ", survey_ID)
    #println("survey output file ", survey_output_file)

    # create the HMD header block

    HMD_output = build_hmdif_header_block(survey_ID)

    #println("HMD header block ", HMD_output)
    #create the survey name and survey file name
    survey_hmd_record = create_survey_record(survey_ID)
    push!(HMD_output, survey_hmd_record)

    #println("Processing survey to gdf ")
    network_gdf = DataFrames.groupby(combined_df, :Network)

    # counts the number of section records so the count is maintained acrocc the potential changes in the Client 
    # network number/id
    section_record_count::Integer = 0

    for gdf in network_gdf
        #println("Network ", gdf.Network[1])
        # if there is nothing in the network (gdf length is 0)
        # process the next gdf
        if nrow(gdf) == 0
            continue
        end
        #println("gdf ", gdf)
        #println("gdf names ", names(gdf))
        #println("gdf length ", nrow(gdf))
        #println("gdf type ", typeof(gdf))
        #println("gdf section ID ", gdf.SectionID[1])
        #println("gdf section number ", gdf.sectionNr[1])
        #println("gdf start chainage ", first(gdf.Chainage))
        #println("gdf last chainage ", last(gdf.Chainage))
        #println("gdf length ", last(gdf.Chainage) - first(gdf.Chainage))
        standard_df = DataFrame(gdf)
        returned_records, section_record_count = process_combined_data(standard_df, survey_ID, section_record_count)
        #returned_records = join(returned_records)
        #println(typeof(returned_records), " ", length(returned_records), " records returned from process_combined_data")
        #println(typeof(HMD_output), " ", length(HMD_output))
        #println("typeof HMD_output :", typeof(HMD_output))
        #println("typeof returned_records :", typeof(returned_records))
        append!(HMD_output, returned_records)
    end

    filter!(s -> !isempty(s), HMD_output)

    hmd_tail = hmd_tail_records(HMD_output)

        #println("hmd_tail ", hmd_tail)

    # add the tail records to the HMD output
    append!(HMD_output, hmd_tail)

    #println("HMD output type ", typeof(HMD_output))

    # write the HMD output to a file
    survey_output_file = string(replace(grid_file_name, ".grd" => ".HMD"))
    println("Writing HMDIF output to file ", survey_output_file)

    file = open(survey_output_file, "w")
    try
        for line in HMD_output
            if length(line) > 3
                write(file, String(line))
            end
        end
    finally
        close(file)
    end
    println("Finished writing HMDIF output to file ", survey_output_file)
    return (true, nothing)
end