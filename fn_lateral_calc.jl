function fn_lateral_calc(section_df,returned_clusters, returned_rows) 
    
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

    # remane the columns to get rid of any underscores

    rename!(section_df, names(section_df) .=> replace.(names(section_df), "_" => ""))

    # remove the columns with string names and the under score at the front of the names

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


    # Extract all 'a' values (the first component)
    # The expression `getindex.(cartesian_vector, 1)` uses broadcasting (`.`)
    # to apply `getindex(::CartesianIndex, 1)` to every element.
    row_values = getindex.(returned_clusters, 1)

    #Extract all 'b' values (the second component)
    col_values = getindex.(returned_clusters, 2)


    # 3. Find the min/max for each component
    min_rows = minimum(row_values)
    max_rows = maximum(row_values)

    min_cols = minimum(col_values)
    max_cols = maximum(col_values)

    # calcualte size of rows and cols for the defect

    size_rows = ((max_rows - min_rows) + 0.2) / 5 # 5 rows per metre (+ 0.2 as there is no row at 0m)
    ## the col numbers are at the end of the width so 400 -200 is 200 cm and never includes the lowest of the two values.
    # in this example column 200 actually starts at 0 (but there is no column 0 to calculate with)
    size_cols = ((max_cols - min_cols) * 200) + 200 

    # calculate the lateral extent (see ukpms user man, vol 2, ch 7, pg 8)
    # width of the carriageway is the last heading of the section dataframe 
    #println("sect_df names : ", names(section_df))
    max_lateral_extent = parse(Int64, names(section_df)[end])

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
    lateral_extent_range = divide_into_eighths_comp(max_lateral_extent)
    #println(lateral_extent_range)

    # find out which of the 'brackets' in the lateral_extent_range the defect size (size_cols) fits
    # so for a 4m width the lateral_extent_range is 
    # [500.0, 1000.0, 1500.0, 2000.0, 2500.0, 3000.0, 3500.0, 4000.0] it's the eighths.
    # need to find the lateral extent in terms of the proportion where the size cols fits.

    # get the values we are interested in from the lateral_extent_range
    indices_to_keep = [1, 2, 4, 6, 8]

    lateral_extent_values_of_interest = lateral_extent_range[indices_to_keep]

    #println("lateral extent brackets : ", lateral_extent_values_of_interest)

    extent_position = findfirst(x -> size_cols <= x, lateral_extent_values_of_interest)

    #println("extent_position : ", extent_position)

    function assign_value_vector(n::Int)
        
        # these are the multipliers for the transverse/lateral extent
        VALUE_VECTOR = [0.125, 0.25, 0.5, 0.75, 1] 

        # Check bounds before indexing to avoid an error
        if 1 <= n <= length(VALUE_VECTOR)
            return VALUE_VECTOR[n]
        else
            return 2
        end
    end

    extent_value = assign_value_vector(extent_position)

    #println("extent_value : ", extent_value)

    # length of defect = size_rows (five rows per metre and calc is above here)
    # extent of defect = extent_value
    # subection length = length of the section_df / 5 (five rows per metre)
    # subsection_area = subsection_length * 1 (1 is the full extent/width)

    # Defect area

    subsection_length = (nrow(section_df) / 5) - 0.2 # because each row is 0.2m and nrow returns one too many

    #println("subsection_length ", subsection_length)

    defect_area = (size_rows) * extent_value

    #println("defect_area ", defect_area)

    defect_percentage = (defect_area / subsection_length) * 100



    if typeof(defect_percentage) == "String"
        defect_percentage = parse(Float64, direct_percentage)
    end

    return_defect_percentage = round(defect_percentage, digits=2)

    return return_defect_percentage

end