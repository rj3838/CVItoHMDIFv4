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
    # The .grd file contains two data blocks. The second block (GPS/measurement data)
    # has more columns than the first block (CVI observations), causing CSV to create
    # auto-named extra columns (Column7, Column8, ...). First-block rows have missing
    # in those extra columns; second-block rows have values. We keep only first-block rows.
    if ncol(input_df) > 6
        extra_cols = names(input_df)[7:end]
        first_block_mask = vec(all(ismissing.(Matrix(input_df[!, extra_cols])), dims=2))
        DataFrames.select!(input_df, 1:6)
        input_df = input_df[first_block_mask, :]
    end
    # drop the rows with a missing item this is everything after and including the empty line
    #dropmissing!(input_df)

    # drop the empty columns
    #empty_cols = names(input_df)[all(col -> all(ismissing, input_df[!, col]), names(input_df))]
    #df.select!(input_df, Not(empty_cols))

    # Drop empty columns (Union{} type) and all-missing columns
    # cols_to_keep = [col for col in names(input_df) 
    #                 if eltype(input_df[!, col]) != Union{} && 
    #                    !all(ismissing, input_df[!, col])]

    # Remove columns whose name contains "Column"
    #cols_to_keep = [col for col in names(input_df) if !occursin("Column", col)]

    #input_df= select(input_df, cols_to_keep)
    # Trim at CHARTCrack marker BEFORE dropmissing, so the marker row isn't removed
    # before we can find it. The empty line between the last data row and CHARTCrack
    # accounts for the -2 offset (keeps all good data rows).
    first_col = names(input_df)[1]
    chartcrack_idx = findfirst(
        row -> !ismissing(row[first_col]) && occursin("CHARTCrack", string(row[first_col])),
        eachrow(input_df)
    )
    if !isnothing(chartcrack_idx)
        keep_until = max(0, chartcrack_idx - 2)
        input_df = input_df[1:keep_until, :]
    end

    DataFrames.dropmissing!(input_df)

    # Drop trailing columns that are entirely missing (e.g. extra fields from trailing commas)
    # Work from the end backwards and stop at the first column with any non-missing value
    while ncol(input_df) > 0 && all(ismissing, input_df[!, end])
        DataFrames.select!(input_df, 1:ncol(input_df)-1)
    end

    # drop the rows with a missing item this is everything after and including the empty line
    dropmissing!(input_df)
   
    return input_df
end
