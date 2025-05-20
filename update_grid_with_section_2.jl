using CSV, DataFrames

function update_section(grd_df, csv_df)
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
    println("update_grid_with_section.jl")
    println(names(grd_df))
    println(names(csv_df))
# 2. Read the .csv file (assuming standard CSV with columns: Section, GRD Start Ch, GRD End Ch)
#csv_df = CSV.read("Zone1_Route1.csv", DataFrame)
#rename!(csv_df, :"GRD Start Ch" => :"GRD_Start_Ch")
#rename!(csv_df, :"GRD End Ch" => :"GRD_End_Ch")
#transform!(csv_df, :Chainage => ByRow(x -> tryparse(Float64, x)) => :Chainage) 

# 3. Ensure columns are the correct type
grd_df.Chainage = parse.(Float64, grd_df.Chainage)
#csv_df.GRD_Start_Ch = parse.(Float64, csv_df."GRD Start Ch")
#csv_df.GRD_End_Ch = parse.(Float64, csv_df."GRD End Ch")

# 4. Filter and update Section
    result_rows = DataFrame()

    for i in 1:nrow(csv_df)
        # Find rows in grd_df where Chainage is in the current csv_df row's range
        mask = (grd_df.Chainage .>= csv_df.GRD_Start_Ch[i]) .& (grd_df.Chainage .<= csv_df.GRD_End_Ch[i])
        temp = grd_df[mask, :]
        temp.SectionID .= csv_df.Section[i]  # Update Section column
        temp.Direction = fill(csv_df.Direction[i], nrow(temp))
        temp.StartCh = fill(csv_df."Start Ch"[i], nrow(temp))
        temp.EndCh = fill(csv_df."End Ch"[i], nrow(temp))
        temp.Length = fill(csv_df.Length[i], nrow(temp))
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
    select!(result_rows, Not(:"Section ID"))

    println("result_rows after drop of section ID ",names(result_rows))

    select!(result_rows, Cols(:SectionID, Not(:SectionID)))
    #
    #println(last(result_rows,5))

    CSV.write("updated_grid.csv", result_rows, delim=',', header=true, writeheader=true,
                append=false, quotechar='"', stringtype=string)
end
