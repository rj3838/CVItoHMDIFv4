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

    # Extract all 'a' values (the first component)
    # The expression `getindex.(cartesian_vector, 1)` uses broadcasting (`.`)
    # to apply `getindex(::CartesianIndex, 1)` to every element.
    row_values = getindex.(returned_clusters, 1)

    # 2. Extract all 'b' values (the second component)
    col_values = getindex.(returned_clusters, 2)


    # 3. Find the min/max for each component
    min_rows = minimum(row_values)
    max_rows = maximum(row_values)

    min_cols = minimum(col_values)
    max_cols = maximum(col_values)

    # calcualte size of rows and cols

    size_rows = ((max_rows - min_rows) + 0.2) * 5 # 5 rows per metre
    ## the col numbers are at the end of the width so 400 -200 is 200 cm and never includes the lowest of the two values.
    size_cols = ((max_cols - min_cols) * 200) + 200 

    # calculate the lateral extent (see ukpms user man, vol 2, ch 7, pg 8)
    # width of the carriageway is the last heading of the section dataframe 

    lateral_extent = parse(Int64, names(section_df)[end])

    println("lateral_extent ", lateral_extent)
    println(typeof(lateral_extent))
    #numeric_lateral_extent = parse(Int, lateral_extent)
    #println(numeric_lateral_extent)
    println("defect_size :", size_cols)

    function divide_into_eighths_comp(n::Integer)::Vector{Float64}
        # For each multiplier 'i' from 1 to 8, calculate i * n / 8.
        # Julia's promotion rules ensure the result is a Float64.
        return [i * n / 8.0 for i in 1:8]
    end

# Example: Dividing the integer lateral_extent into eighths
    result_2 = divide_into_eighths_comp(lateral_extent)

    println(result_2)

    # drop the SectionID, Chainage and sectionNr columns from the section DataFrame

    #local_section_df = select(section_df, Not(:Chainage))
    #local_section_df = section_df

    #get the numbered cols as strings

    section_str_cols = names(section_df)

    # convert the column names to a integers (in a vector). 
    # so we can then perform calculation on them.

    section_int_cols = string_vector_to_int_vector(section_str_cols)
    
    #start_width = section_int_cols[first_column]
    #println("start width ", start_width)
    #end_width = section_int_cols[last_column]
    #println("end width ", end_width)
    #min_width = section_int_cols[1]
    # add 200 to the width as the 'cols' are 200 wide !
    #min_width = (end_width - start_width) + 200 
    #min_width_in_m = min_width / 1000
    #println("min width ", min_width)
    #max_width = section_int_cols[end]
    #println("max width ", max_width)
    #column_interval = section_int_cols[2] - min_width
    #println("column_width ", column_interval)
    
    #defect_width = (end_width - start_width) + 200 # in mm
    #defect_width_in_m = defect_width / 1000
    #println("Defect width m: ", defect_width_in_m)

    # if the defect width is less than 1m do not report it
    #section_width = max_width - min_width + 200 #there is no 0 column so add 200 to get the full width

    #calculate the length of the defect (needed for the area calc)

    #first_inner_vector = first(returned_clusters)
    #first_row = (first_inner_vector)[1]
    #println("first_row ", first_row)
    #last_inner_vector = last(returned_clusters)
    #last_row = (last_inner_vector)[1]
    #println("last_row ", last_row)
    #println("section_df ", section_df)
    #start_chainage = section_df.Chainage[first_row]
    #println("start chainage ", start_chainage)
    #end_chainage = section_df.Chainage[last_row]
    #println("End chainage : ", end_chainage)

    #total length Σ (end_chainage - start_chainage) from the spec !
    # multiply the length by 1000 as the length is in metres and the width is in mm !
    # that way the area works !
    #defect_length = (end_chainage - start_chainage) 
    # each grid row is 0.2m so the defect_length is divided by 5
    #defect_length = (last_row - first_row) / 5
    #println("defect length m: ", defect_length)

    #defect_area = defect_length * defect_width_in_m
    #println("defect area m^2: ", defect_area)

    #defect_percentage = (defect_width/section_width) * 100
    # the total area of a 20m subsection is ...
    # 20000 mm (length) x 4000 mm = 80000000
    # 20m x 4m = 80 m^2
    # calculate the section area as the number of rows in the section_df
    # this takes care of the last section being less that 20m !
    #section_length = size(section_df)[1] / 5

    #defect_percentage = (defect_area/section_length) * 100
    #println(defect_percentage)
    #println("section_df ", local_section_df)

    #println("defect_percentage ",defect_percentage)

    #defect_percentage = round(defect_percentage, digits=2)
    #println("rounded percentage ", defect_perc_rounded)
    #println("rounded defect_percentage ",defect_percentage)

    if typeof(defect_percentage) == "String"
        defect_percentage = parse(Float64, direct_percentage)
    end

    return_defect_percentage = round(defect_percentage, digits=2)

    return return_defect_percentage
    #return Float64(99.9) # this does always return 99.9

end