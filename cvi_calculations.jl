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

# function fn_lateral_calc(section_df,returned_clusters, returned_rows) 
    
#     function string_vector_to_int_vector(str_vec::Vector{String})::Vector{Int64}
#     # this converts a vector of strings to a vector of integers (deals with column headers)
#         # remove the underscore from the column names passed in to the function.
#         str_vec = replace.(str_vec, "_" => "")
#         int_vec = Vector{Int64}(undef, length(str_vec))
#         for i in eachindex(str_vec[1:20])
#             #println(str_vec)
#             try
#                 int_vec[i] = parse(Int16, str_vec[i])
#                 #int_vec[i] = parse(Int64, str_vec[i])
#             catch e
#                 if e isa ArgumentError
#                     @warn "Could not parse string '$(str_vec[i])' to Int64 at index $i. Skipping this element."
#                 else
#                     rethrow(e) # Re-throw other types of errors
#                 end
#             end
#         end
#         return filter(!isnan, int_vec) # Remove any NaN values that might have resulted from parsing failures
#     end

#     # returned clusters is the position of the error code on the grid.
#     # returned cluster should be sorted to give the positions in order
    
#     #println("type of returned clusters ",typeof(returned_clusters))
#     sort!(returned_clusters)
#     #println("vector of returned_clusters ",returned_clusters)
#     first_inner_vector = first(returned_clusters)
#     #println("first_inner_vector", first_inner_vector)
#     first_column = (first_inner_vector)[2]
#     #println("first_column ", first_column)
#     last_inner_vector = maximum(returned_clusters)
#     #println("last_inner_vector ", last_inner_vector)
#     last_column = (last_inner_vector)[2]
#     #println("last_column ", last_column)

#     # drop the SectionID, Chainage and sectionNr columns from the section DataFrame

#     local_section_df = select(section_df, Not(:Chainage))

#     #get the numbered cols as strings

#     section_str_cols = names(local_section_df)

#     # convert the column names to a integers (in a vector). 
#     # so we can then perform calculation on them.

#     section_int_cols = string_vector_to_int_vector(section_str_cols)
    
#     start_width = section_int_cols[first_column]
#     #println("start width ", start_width)
#     end_width = section_int_cols[last_column]
#     #println("end width ", end_width)
#     #min_width = section_int_cols[1]
#     # add 200 to the width as the 'cols' are 200 wide !
#     min_width = (end_width - start_width) + 200 
#     min_width_in_m = min_width / 1000
#     #println("min width ", min_width)
#     #max_width = section_int_cols[end]
#     #println("max width ", max_width)
#     #column_interval = section_int_cols[2] - min_width
#     #println("column_width ", column_interval)
    
#     defect_width = (end_width - start_width) + 200 # in mm
#     defect_width_in_m = defect_width / 1000
#     #println("Defect width mm: ", defect_width)

#     # if the defect width is less than 1m do not report it
#     #section_width = max_width - min_width + 200 #there is no 0 column so add 200 to get the full width

#     #calculate the length of the defect (needed for the area calc)

#     #first_inner_vector = first(returned_clusters)
#     first_row = (first_inner_vector)[1]
#     println("first_row ", first_row)
#     #last_inner_vector = last(returned_clusters)
#     last_row = (last_inner_vector)[1]
#     println("last_row ", last_row)
#     #println("section_df ", section_df)
#     start_chainage = section_df.Chainage[first_row]
#     println("start chainage ", start_chainage)
#     end_chainage = section_df.Chainage[last_row]
#     println("End chainage : ", end_chainage)

#     #total length Σ (end_chainage - start_chainage) from the spec !
#     # multiply the length by 1000 as the length is in metres and the width is in mm !
#     # that way the area works !
#     defect_length = (end_chainage - start_chainage) 
#     println("defect length m: ", defect_length)

#     defect_area = defect_length * defect_width_in_m
#     println("defect area m^2: ", defect_area)

#     #defect_percentage = (defect_width/section_width) * 100
#     # the total area of a 20m subsection is ...
#     # 20000 mm (length) x 4000 mm = 80000000
#     # 20m x 4m = 80 m^2
#     defect_percentage = (defect_area/80) * 100
#     #println(defect_percentage)
#     #println("section_df ", local_section_df)

#     println("defect_percentage ",defect_percentage)

#     #defect_percentage = round(defect_percentage, digits=2)
#     #println("rounded percentage ", defect_perc_rounded)
#     #println("rounded defect_percentage ",defect_percentage)

#     if typeof(defect_percentage) == "String"
#         defect_percentage = parse(Float64, direct_percentage)
#     end

#     return_defect_percentage = round(defect_percentage, digits=2)

#     return return_defect_percentage

# end

function fn_count_calc(section_df,returned_clusters, returned_rows) 

    println("type of returned clusters ",typeof(returned_clusters))
    defect_rows = size(returned_clusters)[1]

    # converting to float as the other calculations for the OBVAL record return a float64
    # before rounding to two decimal places. It's easier to do this here than change the generic BVAL code

    defect_rows_float = float(defect_rows)
    println(returned_clusters, " ", defect_rows_float)
    #defect_rows = returned_rows
    return defect_rows_float

end