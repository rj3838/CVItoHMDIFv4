function read_data_grid(filepath::String)

    #csv_file = "Zone1_Route1.grd"

    # Read the CSV file into a DataFrame
    input_df = CSV.read(filepath, DataFrame; delim=',', header=59,
                        silencewarnings=true,
#                        drop_empty_cols=true,
 #                       ignorerepeated=true,
                        normalizenames=true
 #                       missingstring=""
                        )
    # drop the rows with a missing item this is everything after and including the empty line
    dropmissing!(input_df)

    # drop the empty columns
    #empty_cols = names(input_df)[all(col -> all(ismissing, input_df[!, col]), names(input_df))]
    #df.select!(input_df, Not(empty_cols))

    # Drop empty columns (Union{} type) and all-missing columns
    # cols_to_keep = [col for col in names(input_df) 
    #                 if eltype(input_df[!, col]) != Union{} && 
    #                    !all(ismissing, input_df[!, col])]

    # Remove columns whose name contains "Column"
    cols_to_keep = [col for col in names(input_df) if !occursin("Column", col)]

    input_df= select(input_df, cols_to_keep)
   
    return input_df
end
