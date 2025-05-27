function read_data_grid(filepath::String)

    #csv_file = "Zone1_Route1.grd"

    # Read the CSV file into a DataFrame
    input_df = CSV.read(filepath, DataFrame; delim=',', header=22,
                        silencewarnings=true,
 #                       ignorerepeated=true,
                        normalizenames=true,
                        missingstring="")
    # drop the rows with a missing item this is everything after and including the empty line
    input_df = dropmissing(input_df)
        
       
    return input_df
end
