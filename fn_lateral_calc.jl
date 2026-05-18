function fn_lateral_calc(section_df,returned_clusters, section_length, survey_length_of_row)
    
    function string_vector_to_int_vector(str_vec::Vector{String})::Vector{Int64}
    # this converts a vector of strings to a vector of integers (deals with column headers)
        # remove the underscore from the column names passed in to the function.
        str_vec = replace.(str_vec, "_" => "")
        int_vec = Vector{Int64}(undef, length(str_vec))
        for i in eachindex(str_vec[1:20])
            #println(str_vec)
            try
                int_vec[i] = parse(Int16, str_vec[i])
                #int_vec[i] = parse(Int64, str_vec[i])
            catch e
                if e isa ArgumentError
                    @warn "Could not parse string '$(str_vec[i])' to Int64 at index $i. Skipping this element."
                else
                    rethrow(e) # Re-throw other types of errors
                end
            end
        end
        return filter(!isnan, int_vec) # Remove any NaN values that might have resulted from parsing failures
    end

    # returned clusters is the position of the error code on the grid.
    # returned cluster should be sorted to give the positions in order

    #println("type of returned clusters ",typeof(returned_clusters))
    # sort!(returned_clusters)
    # println("vector of returned_clusters ",returned_clusters)
    # first_inner_vector = first(returned_clusters)
    # println("first_inner_vector", first_inner_vector)
    # first_column = (first_inner_vector)[2]
    # println("first_column ", first_column)
    # last_inner_vector = maximum(returned_clusters)
    # println("last_inner_vector ", last_inner_vector)
    # last_column = (last_inner_vector)[2]
    # println("last_column ", last_column)
    # calculate the length of a row in the section_df
    # at this stage the row chainage is still there it is t so

    #length_of_subsection_rows = diff(section_df[!,t])[1]
    number_of_subsection_rows = nrow(section_df)

    # remane the columns to get rid of any underscores
    #println("column names before renaming : ", names(section_df))

    rename!(section_df, names(section_df) .=> replace.(names(section_df), "_" => ""))

    # remove the columns with string names and the under score at the front of the names
    #println("column names before removing non numeric columns : ", names(section_df))
    #println("first 5 rows : ")
    #print(first(section_df, 5))
    #section_length = section_df[1, "Length"]
    println("section length in lateral calc", section_length)

    # Get all column names
    all_names = names(section_df)

    # Use a list comprehension and tryparse to filter column names.
    # This returns a vector containing only the names that can be parsed to a number.
    numeric_column_names = [
        name for name in all_names 
        if tryparse(Float64, name) !== nothing
    ]

    # Use select! to keep only the columns identified as numeric
    # This operation modifies the DataFrame 'df' in place.
    DataFrames.select!(section_df, numeric_column_names)

    #println("Final DataFrame Column Names:")
    #println(names(section_df))

    conv_numeric_column_names = parse.(Int,numeric_column_names)
    #println("gap is : ", diff(conv_numeric_column_names))

    # calculate the size of the column (teansverse) 

    width_of_cols = diff(conv_numeric_column_names)[1]

    number_of_cols = length(conv_numeric_column_names)
    println("width of cols ", width_of_cols)
    println("number of cols ", number_of_cols)

    # Extract all 'a' values (the first component)
    # The expression `getindex.(cartesian_vector, 1)` uses broadcasting (`.`)
    # to apply `getindex(::CartesianIndex, 1)` to every element.
    row_values = getindex.(returned_clusters, 1)

    #Extract all 'b' values (the second component)
    #col_values = getindex.(returned_clusters, 2)


    # 3. Find the min/max for each component
    min_rows = minimum(row_values)
    max_rows = maximum(row_values)

    println("min row ", min_rows)
    println("max row ", max_rows)

    #min_cols = minimum(col_values)
    #max_cols = maximum(col_values)

    # calcualte size of rows and cols for the defect

    #size_rows = width_of_cols # calc is above

    println("column names in lateral calc: ", names(section_df))

    rows_in_section = nrow(section_df)
    #length_of_section = section_df.Length[1] # length is the first column in the section_df and is the same for all rows in the section_df

    println("rows in section ", rows_in_section)
    println("length of section ", section_length)

    #size_rows = section_length / rows_in_section # so we can calculate the longitudinal length of each row (distance surveyed)
    #size_rows = ((max_rows - min_rows) + 0.2) / 5 # 5 rows per metre (+ 0.2 as there is no row at 0m)
    ## the col numbers are at the end of the width so 400 -200 is 200 cm and never includes the lowest of the two values.
    # in this example column 200 actually starts at 0 (but there is no column 0 to calculate with)
    #size_cols = ((max_cols - min_cols) * 200) + 200 
    #size_cols = width_of_cols # calc is above !
    # calculate the lateral extent (see ukpms user man, vol 2, ch 7, pg 8)
    # width of the carriageway is the last heading of the section dataframe 
    #println("sect_df names : ", names(section_df))
    #max_lateral_extent = parse(Int64, names(section_df)[end])

    #println("max lateral_extent ", max_lateral_extent)
    #println(typeof(max_lateral_extent))
    #numeric_lateral_extent = parse(Int, lateral_extent)
    #println(numeric_lateral_extent)
    #println("defect_size :", size_cols)

    function divide_into_eighths_comp(n::Integer)::Vector{Float64}
        # For each multiplier 'i' from 1 to 8, calculate i * n / 8.
        # Julia's promotion rules ensure the result is a Float64.
        return [i * n / 8.0 for i in 1:8]
    end

    # Example: Dividing the integer lateral_extent into eighths
    #lateral_extent_range = divide_into_eighths_comp(max_lateral_extent)
    #println(lateral_extent_range)

    # find out which of the 'brackets' in the lateral_extent_range the defect size (size_cols) fits
    # so for a 4m width the lateral_extent_range is 
    # [500.0, 1000.0, 1500.0, 2000.0, 2500.0, 3000.0, 3500.0, 4000.0] it's the eighths.

    defect_area_cells = length(returned_clusters)
    subsection_area_cells = rows_in_section * number_of_cols

    println("defect area cells: ", defect_area_cells)
    println("subsection area cells: ", subsection_area_cells)

    defect_percentage = (defect_area_cells / subsection_area_cells) * 100

    defect_percentage = Float64(defect_percentage)

    println("defect % :", defect_percentage)

    return_defect_percentage = round(defect_percentage, digits=2)

    return return_defect_percentage

end