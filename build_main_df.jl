# combine the grid, route and section dataframes to create a single dataframe
using DataFrames

function build_main_df(grid_df, route_df, section_df)
    # Ensure the dataframes have the necessary columns
    # required_grid_cols = [:grid_id, :grid_name, :grid_type]
    # required_route_cols = [:route_id, :route_name, :grid_id]
    # required_section_cols = [:section_id, :section_name, :route_id]

    # for col in required_grid_cols
    #     if !haskey(grid_df, col)
    #         error("Missing column $col in grid_df")
    #     end
    # end

    # for col in required_route_cols
    #     if !haskey(route_df, col)
    #         error("Missing column $col in route_df")
    #     end
    # end

    # for col in required_section_cols
    #     if !haskey(section_df, col)
    #         error("Missing column $col in section_df")
    #     end
    # end

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

    # check the result_rows column names
    #println("Result Rows Column Names: ", names(result_rows))
    CSV.write("temp_rows.csv", result_rows, delim=',', header=true, writeheader=true,
                append=false, quotechar='"', stringtype=string)

    # drop the section ID column
    select!(result_rows, Not(:Section_ID))

    #println("result_rows after drop of section ID ",names(result_rows))

    select!(result_rows, Cols(:SectionID, Not(:SectionID)))
    #
    #println("result_rows after drop of section ID ",names(result_rows))
    #println("result_rows typeof: ", typeof(result_rows))

    # change the section column names to match result_row names
    rename!(section_df, :Section_ID => :SectionID)

    # need to rename the authority name titled column (num 13) to Network
    old_name = names(section_df)[13]
    new_name = :Network
    rename!(section_df, old_name => new_name)

    # Ensure the section_df has the correct column names
    #println("Section DataFrame Column Names: ", names(section_df))


    # Now add the section information to the result_rows

    combined_df = leftjoin(result_rows, section_df, on=:SectionID)
# Ensure the combined_df has the correct column names
    println("Combined DataFrame Column Names: ", names(combined_df))

# tidy up the column headers we don't need all of them !
    select!(combined_df, Not([:SECTION_DE, 
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
    rename!(combined_df, Symbol.(replace.(names(combined_df), r"^_" => "")))

    # sort the combined_df so that where there were diversions in the survey and the route comes back to the same section
    # in this way the section data will be in sequence

    sort!(combined_df, [:SectionID, :Chainage, :Direction])

    # Write the combined DataFrame to a CSV file    

    CSV.write("updated_grid.csv", combined_df, delim=',', header=true, writeheader=true,
                append=false, quotechar='"', stringtype=string)

    
    return combined_df
    
end