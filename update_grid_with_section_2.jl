using CSV, DataFrames

function update_section(grid_df, route_df)
    # Ensure columns are the correct type
    grid_df.Chainage = parse.(Float64, grid_df.Chainage)

    # Filter and update Section
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

# result_rows now contains the filtered and updated DataFrame

#print the column heraders
    #println("result_rows ",names(result_rows))

    # drop the section ID column
    select!(result_rows, Not(:Section_ID))

    #println("result_rows after drop of section ID ",names(result_rows))

    select!(result_rows, Cols(:SectionID, Not(:SectionID)))
    #
    #println(last(result_rows,5))

    CSV.write("updated_grid.csv", result_rows, delim=',', header=true, writeheader=true,
                append=false, quotechar='"', stringtype=string)

    return result_rows
end
