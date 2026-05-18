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
    # Trim at CHARTCrack marker FIRST, before any other filtering.
    # The CHARTCrack row may have data in extra columns (7+) which would cause it to be
    # removed by the first_block_mask filter below, leaving its trailing rows (e.g.
    # "Total Chainage" header rows) orphaned in the dataframe. By trimming here we are
    # guaranteed to find the marker while it is still present.
    # The blank row before CHARTCrack is at chartcrack_idx-1, so keeping 1:chartcrack_idx-2
    # retains all good data rows and discards the blank row and everything after it.
    first_col = names(input_df)[1]
    chartcrack_idx = findfirst(
        row -> !ismissing(row[first_col]) && occursin("CHARTCrack", string(row[first_col])),
        eachrow(input_df)
    )
    if !isnothing(chartcrack_idx)
        keep_until = max(0, chartcrack_idx - 2)
        input_df = input_df[1:keep_until, :]
    end

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
