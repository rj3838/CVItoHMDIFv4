using CSV, DataFrames

function update_section(grid_df, route_df)
    # Ensure the columns are of the correct type
    #grd_df.Chainage = parse.(Float64, grd_df.Chainage)
    #csv_df.GRD_Start_Ch = parse.(Float64, csv_df."GRD Start Ch")
    #csv_df.GRD_End_Ch = parse.(Float64, csv_df."GRD End Ch")

    # Filter and update Section
    # result_rows = DataFrame()

    # for i in 1:nrow(csv_df)
    #     # Find rows in grd_df where Chainage is in the current csv_df row's range
    #     mask = (grd_df.Chainage .>= csv_df.GRD_Start_Ch[i]) .& (grd_df.Chainage .<= csv_df.GRD_End_Ch[i])
    #     temp = grd_df[mask, :]
    #     temp.SectionID .= csv_df.Section[i]  # Update Section column
    #     temp.Direction = fill(csv_df.Direction[i], nrow(temp))
    #     temp.StartCh = fill(csv_df."Start Ch"[i], nrow(temp))
    #     temp.EndCh = fill(csv_df."End Ch"[i], nrow(temp))
    #     temp.Length = fill(csv_df.Length[i], nrow(temp))
    #     append!(result_rows, temp)
    # end

    # return result_rows

    #println("in update_section.jl")

# 1. Read the .grd file, skipping the first 22 rows and then drop the rows with a missing
#include("read_grid.jl")
#grd_df = CSV.read("Zone1_Route1.grd", DataFrame; header=22, delim=',', ignorerepeated=true,
#                   silencewarnings=true)
#dropmissing!(grd_df)
#grd_df = read_data_grid()

# make sure chainage is numeric.
#transform!(grd_df, :Chainage => ByRow(x -> tryparse(Float64, x)) => :Chainage)
    #println("update_grid_with_section_2.jl")
    println("grid_df ",names(grid_df))
    println("route_df",names(route_df))
# 2. Read the .csv file (assuming standard CSV with columns: Section, GRD Start Ch, GRD End Ch)
#csv_df = CSV.read("Zone1_Route1.csv", DataFrame)
#rename!(csv_df, :"GRD Start Ch" => :"GRD_Start_Ch")
#rename!(csv_df, :"GRD End Ch" => :"GRD_End_Ch")
#transform!(csv_df, :Chainage => ByRow(x -> tryparse(Float64, x)) => :Chainage)

    # data_end = findfirst(=="", grid_df."Section ID")

    #     if data_end !== nothing
    #         println("Data end found at index: ", data_end)
    #         # Drop rows from the first missing value onwards
    #         grid_df = grid_df[1:data_end-1, :]
    #     else
    #         println("No missing values found in Chainage column.")
    #     end

    # Check for empty rows (all missing)
    # This will find the first row where all values are missing
    # and drop all rows after that.
# Find the index of the first "empty" row (all missing)

    #all_missing_rows = [all(ismissing, collect(r)) for r in eachrow(grid_df)]
    # first_empty_idx = findfirst(ismissing, grid_df[:,:Chainage])

    # if first_empty_idx !== nothing
    #     println("\nFirst empty row (all missing) found at index: ", first_empty_idx)

    #     # Drop the rest of the DataFrame (keep rows from 1 up to first_empty_idx - 1)
    #     df_truncated = grid_df[1:first_empty_idx-1, :]

    #     println("\nDataFrame after dropping rows from the first empty row onwards:")
    #     println(df_truncated)
    # else
    #     println("\nNo row with all missing values found. DataFrame remains unchanged.")
    #     df_truncated = grid_df # If no empty row, keep the original DataFrame
    # end

    # # # Find the index of the first non-numeric chainage value this removes the (any) data after the grid info
    # #     idx = findfirst(x -> !(ismissing(x)), grd_df."Section ID")

    # #     if !isnothing(idx) # a non numeric is found
    # #         # Keep only rows before the first non-numeric value
    # #         grd_df = grd_df[1:idx-1, :]
    # #     end
    # grid_df = df_truncated

    println("grid length",nrow(grid_df))

    # 3. Ensure columns are the correct type
    grid_df.Chainage = parse.(Float64, grid_df.Chainage)
    #csv_df.GRD_Start_Ch = parse.(Float64, csv_df."GRD Start Ch")
    #csv_df.GRD_End_Ch = parse.(Float64, csv_df."GRD End Ch")

    # remove the spaces in the column names and replace with underscores
    #rename(route_df,:"GRD Start Ch" => :"GRD_Start_Ch")
    #rename(route_df,:"GRD End Ch" => :"GRD_End_Ch")
    #rename!(route_df, Symbol.(replace.(names(route_df), r" " => "_"))...)
    # 4. Filter and update Section
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
    println("result_rows ",names(result_rows))

# Drop the section column and replaceit with the section ID it will contain the same throughout the grid file
    #result_rows = select(result_rows, Not(:"Section ID"))

# rename the columns to match the original grid file
    #rename!(result_rows, :SectionID => :"Section ID")
    # sort the DF on the section ID, start chainage and end chainage, length and Direction
    #sort!(result_rows, [:"Section ID", :StartCh, :EndCh, :Length, :Direction],rev=false)

    # move the section ID to the first column
    # result_rows = select(result_rows, [:Section_ID, Not(:Section_ID)])
    # 
    # drop the section ID column
    select!(result_rows, Not(:Section_ID))

    println("result_rows after drop of section ID ",names(result_rows))

    select!(result_rows, Cols(:SectionID, Not(:SectionID)))
    #
    #println(last(result_rows,5))

    CSV.write("updated_grid.csv", result_rows, delim=',', header=true, writeheader=true,
                append=false, quotechar='"', stringtype=string)

    return result_rows
end
