function fn_length_calc(section_df,returned_clusters, returned_rows) 
    
    #println("type of returned clusters ",typeof(returned_clusters))
    #println(returned_clusters)
    first_inner_vector = first(returned_clusters)
    first_row = (first_inner_vector)[1]
    #println("first_row ", first_row)
    last_inner_vector = last(returned_clusters)
    last_row = (last_inner_vector)[1]
    #println("last_row ", last_row)
    #println("section_df ", section_df)
    #start_chainage = section_df.Chainage[first_row]
    #println("start chainage ", start_chainage)
    #end_chainage = section_df.Chainage[last_row]
    #println("end chainage ", end_chainage)
    #min_chainage = section_df.Chainage[1]
    #println("min chainage ", min_chainage)
    #max_chainage = section_df.Chainage[end]
    #println("max chainage ", max_chainage)

    section_length = size(section_df)[1] /5

    defect_length = (last_row - first_row) / 5
    #section_length = max_chainage - min_chainage # will usually be 20m

    #total length Σ (end_chainage - start_chainage)

    defect_percentage = (defect_length/section_length) * 100
    #println("defect_percentage ",defect_percentage)
    #round!(defect_percentage, digits=2)

    if typeof(defect_percentage) == "String"
        defect_percentage = parse(Float64, direct_percentage)
    end

    return_defect_percentage = round(defect_percentage, digits=2)

    return return_defect_percentage

end

function fn_count_calc(section_df,returned_clusters, returned_rows) 

    #println("type of returned clusters ",typeof(returned_clusters))
    defect_rows = size(returned_clusters)[1]

    # converting to float as the other calculations for the OBVAL record return a float64
    # before rounding to two decimal places. It's easier to do this here than change the generic BVAL code

    defect_rows_float = float(defect_rows)
    #println(returned_clusters, " ", defect_rows_float)
    #defect_rows = returned_rows
    return defect_rows_float

end