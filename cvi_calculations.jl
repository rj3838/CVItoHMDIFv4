function fn_length_calc(section_df,returned_clusters, returned_rows) 
    
    println(typeof(returned_clusters))
    first_inner_vector = first(returned_clusters)
    first_row = first(first_inner_vector)[1]
    println("first_row ", first_row)
    last_inner_vector = last(returned_clusters)
    last_row = last(last_inner_vector)[1]
    println("last_row ", last_row)
    println("section_df ", section_df)
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
    println(defect_percentage)

    return defect_percentage

end