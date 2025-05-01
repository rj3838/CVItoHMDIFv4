function fn_length_calc(section_df,returned_clusters, returned_rows) 
    
    println(typeof(returned_clusters))
    first_inner_vector = first(returned_clusters)
    first_row = first(first_inner_vector)[1]
    println("first_row ", first_row)
    last_inner_vector = last(returned_clusters)
    last_row = last(last_inner_vector)[1]
    println("last_row ", last_row)
    #println("section_df ", section_df)
    start_chainage = section_df.Chainage[first_row]
    println("start chainage ", start_chainage)
    end_chainage = section_df.Chainage[last_row]
    println("end chainage ", end_chainage)
    min_chainage = section_df.Chainage[1]
    println("min chainage ", min_chainage)
    max_chainage = section_df.Chainage[end]
    println("max chainage ", max_chainage)

    defect_length = end_chainage - start_chainage
    section_length = max_chainage - min_chainage

    #total length Σ (end_chainage - start_chainage)

    defect_percentage = (defect_length/section_length) * 100
    println("defect_percentage ",defect_percentage)

    if typeof(defect_percentage) == "String"
        defect_percentage = parse(Float64, direct_percentage)
    end

    return defect_percentage

end

function fn_lateral_calc(section_df,returned_clusters, returned_rows) 
    
    function string_vector_to_int_vector(str_vec::Vector{String})::Vector{Int64}
    # this converts a vector of strings to a vector of integers (deals with column headers)
        int_vec = Vector{Int64}(undef, length(str_vec))
        for i in eachindex(str_vec)
            try
                int_vec[i] = parse(Int64, str_vec[i])
            catch e
                if e isa ParseError
                    @warn "Could not parse string '$(str_vec[i])' to Int64 at index $i. Skipping this element."
                else
                    rethrow(e) # Re-throw other types of errors
                end
            end
        end
        return filter(!isnan, int_vec) # Remove any NaN values that might have resulted from parsing failures
    end
    
    println(returned_clusters)
    first_inner_vector = first(returned_clusters)
    first_column = minimum(first_inner_vector)[2]
    println("first_column ", first_column)
    last_inner_vector = maximum(returned_clusters)
    last_column = last(last_inner_vector)[2]
    println("last_column ", last_column)

    # drop the SectionID, Chainage and sectionNr columns from the section DataFrame

    local_section_df = select(section_df, Not([:SectionID, :Chainage]))

    #get the numbered cols as strings

    section_str_cols = names(local_section_df)

    # convert the column names to a integers (in a vector). 
    # we can then perform calculation on them.

    section_int_cols = string_vector_to_int_vector(section_str_cols)
    
    start_width = section_int_cols[first_column]
    println("start width ", start_width)
    end_width = section_int_cols[last_column]
    println("end width ", end_width)
    min_width = section_int_cols[1]
    println("min width ", min_width)
    max_width = section_int_cols[end]
    println("max width ", max_width)
    column_interval = section_int_cols[2] - min_width
    println("column_width ", column_interval)
    
    defect_width = end_width - start_width

    # if the defect width is less than 1m do not report it
    section_width = max_width - min_width + 200 #there is no 0 column so add 200 to get the full width

    #total length Σ (end_chainage - start_chainage) from the spec !

    defect_percentage = (defect_width/section_width) * 100
    #println(defect_percentage)
    println("section_df ", local_section_df)

    println("defect_percentage ",defect_percentage)

    if typeof(defect_percentage) == "String"
        defect_percentage = parse(Float64, direct_percentage)
    end
    return defect_percentage

end

function fn_count_calc(section_df,returned_clusters, returned_rows) 

    defect_rows = returned_rows
    return defect_rows

end