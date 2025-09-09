function route_csv_to_df_processing()
    # This code reads the CSV file containing the Section name, the grid start point (and end point),
    # length and the survey_direction. processes the data, and creates a new column in the DataFrame

    #using CSV
    #using DataFrames

    # Replace "your_file.csv" with the path to your CSV file
    csv_file = "Zone1_Route1.csv"

    # Read the CSV file into a DataFrame
    df = CSV.read(csv_file, DataFrame; delim=',', header=true)

    # produce a combined field using the section and GRD start
    #df.Section_data = string.(df.Section, "_", df."GRD Start Ch")
    rename!(df, :"GRD Start Ch" => :"GRD_Start_Ch")
    rename!(df, :"GRD End Ch" => :"GRD_End_Ch")
    
    transform!(df, [:Section, :GRD_Start_Ch] => ((a, b) -> string.(a .* "_" .* string.(b))) => :Section_data)
    #rintln("df ", df)

    return df

end