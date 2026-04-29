# combine the grid, route and section dataframes to create a single dataframe
import DataFrames as df

function build_main_df(grid_df, route_df, passed_section_df)
    
    # Convert columns to appropriate types if necessary
    grid_df.Chainage = parse.(Float64, grid_df.Chainage)
    #route_df.GRD_Start_Ch = parse.(Float64, route_df.GRD_Start_Ch)
    #route_df.GRD_End_Ch = parse.(Float64, route_df.GRD_End_Ch)
    #section_df.StartCh = parse.(Float64, section_df.StartCh)
    #section_df.EndCh = parse.(Float64, section_df.EndCh)

    # Join the dataframes starting with grid and route

    result_rows = DataFrame()

    for i in 1:nrow(route_df)
        # Find rows in grd_df where Chainage is in the current csv_df row's range
        mask = (grid_df.Chainage .>= route_df.GRD_Start_Ch[i]) .& (grid_df.Chainage .<= route_df.GRD_End_Ch[i])
        temp = grid_df[mask, :]
        temp.SectionID .= route_df.Section[i]  # Update Section column
        temp.Direction = fill(route_df.Direction[i], nrow(temp))
        temp.StartCh = fill(route_df.Start_Ch[i], nrow(temp))
        temp.EndCh = fill(route_df.End_Ch[i], nrow(temp))
        temp.Length = fill(route_df.Length[i], nrow(temp))
        append!(result_rows, temp)
    end

println("DataFrame schema:")
    for col in names(result_rows)
        println("  $col: ", eltype(result_rows[!, col]))
    end



    # check the result_rows column names
    #println("Result Rows Column Names: ", names(result_rows))
    CSV.write("temp_rows.csv", result_rows, delim=',', header=true, writeheader=true,
                append=false, quotechar='"', stringtype=string)

    # drop the section ID column
    df.select!(result_rows, Not(:Section_ID))

    #println("result_rows after drop of section ID ",names(result_rows))

    df.select!(result_rows, Cols(:SectionID, Not(:SectionID)))
    #
    #println("result_rows after drop of section ID ",names(result_rows))
    #println("result_rows typeof: ", typeof(result_rows))
    #println(names(passed_section_df))
    # change the section column names to match result_row names
    if "Section_ID" in names(passed_section_df)
        df.rename!(passed_section_df, :Section_ID => :SectionID)
    end
    #println(names(passed_section_df))
    # need to rename the authority name titled column (num 13) to Network
    old_name = names(passed_section_df)[13]
    new_name = :Network
    #println(names(passed_section_df))
    df.rename!(passed_section_df, old_name => new_name)
    #println(names(passed_section_df))

    # Ensure the section_df has the correct column names
    #println("Section DataFrame Column Names: ", names(section_df))


    # Now add the section information to the result_rows

    combined_df = leftjoin(result_rows, passed_section_df, on=:SectionID)
# Ensure the combined_df has the correct column names
    #println("Combined DataFrame Column Names: ", names(combined_df))

# tidy up the column headers we don't need all of them !
    df.select!(combined_df, Not([:SECTION_DE, 
                            :ROAD_NUMBE, 
                            :ROAD_HIERA,
                            :NO_OF_LANE,
                            :SECTION_WI,
                            :SPEED_LIMI,
                            :ROAD_CLASS,
                            :ROAD_NAME,
                            :DISTRICT_N,
                            :WARD_NAME,
                            :NSG_USRN,
                            :X,
                            :Y,
                            :Route_ID,
                            :Zone]))

    # remove the underscore from column names if there is an underscore at the begining of the column name
    # the numeric ones have an underscore at the beginning as an artifact from chartcrack (Grrrr!)
    df.rename!(combined_df, Symbol.(replace.(names(combined_df), r"^_" => "")))

    # sort the combined_df so that where there were diversions in the survey and the route comes back to the same section
    # in this way the section data will be in sequence

    df.sort!(combined_df, [:SectionID, :Chainage, :Direction])

    # Write the combined DataFrame to a CSV file for testing purposes 

    #CSV.write("updated_grid.csv", combined_df, delim=',', header=true, writeheader=true,
    #            append=false, quotechar='"', stringtype=string)

    
    return combined_df
    
end