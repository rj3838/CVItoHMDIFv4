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
    # Trim at CHARTCrack marker: drop from one line above it to the end
    first_col = names(input_df)[1]
    chartcrack_idx = findfirst(
        row -> !ismissing(row[first_col]) && occursin("CHARTCrack", string(row[first_col])),
        eachrow(input_df)
    )
    if !isnothing(chartcrack_idx)
        keep_until = max(0, chartcrack_idx - 2)
        input_df = input_df[1:keep_until, :]
    end

    # Drop trailing columns that are entirely missing (e.g. extra fields from trailing commas)
    # Work from the end backwards and stop at the first column with any non-missing value
    while ncol(input_df) > 0 && all(ismissing, input_df[!, end])
        DataFrames.select!(input_df, 1:ncol(input_df)-1)
    end

    # drop the rows with a missing item this is everything after and including the empty line
    dropmissing!(input_df)
   
    return input_df
end
