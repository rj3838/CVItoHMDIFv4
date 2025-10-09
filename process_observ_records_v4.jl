using DataFrames

function replace_and_expand(v::Vector{T}, old_item::T, new_items::Vector{T}) where T
    # Find the index of the item to be replaced
    idx = findfirst(x -> x == old_item, v)

    # If the item is found, replace and expand
    if idx !== nothing
        return vcat(v[1:idx-1], new_items, v[idx+1:end])
    else
        return v
    end
end

function process_observ_records(section_df::DataFrame, observation_number::Int16)
    #println("starting process obsvervation records for section: ", section_df.SectionID[1])
    # this is used to return the records
    hmd_return_records = []
    observ_defect_record = ""
    obval_defect_record = ""
    obval_indicator = false
    obval_record = false

    # The chainage for each observation will be
    section_start_chainage = section_df.StartCh[1]
    section_end_chainage = section_df.EndCh[1]

    println("start ch : ", section_start_chainage," end ch : ", section_end_chainage)

    #println("section names: ",names(section_df))
    #println(typeof(section_df))

    # this list is used to track which directions have been processed in the section_df so we can create BUTS records if needed
    # for directions with defects 
    direction_processed_list = []

    # convert the section_df from a grouped DF to a standard DF before i do anything to it.
    conv_section_df = DataFrame(section_df)

    # check to see if the section_df contains only zeros in the defect columns
    # if it does then we can skip processing this section_df

    defect_df = select(conv_section_df, 3:22)  # Adjust column indices as needed

    # Iterate through columns and convert floats
    for name in names(defect_df)
        # Check if the column type is a floating-point type
        if eltype(defect_df[!, name]) <: AbstractFloat
            # First, convert floats to integers (truncates decimal part)
            defect_df[!, name] .= Int.(defect_df[!, name])
            
            # Second, convert the new integer values to strings
            defect_df[!, name] .= string.(defect_df[!, name])
        else
            # For non-float columns, just convert them to strings
            defect_df[!, name] .= string.(defect_df[!, name])
        end
    end

    #println(defect_df)

    # read the defect code list

    defect_code_list = CSV.read("CVI_Defect_code_info.csv", 
                                DataFrame; delim=',', 
                                header=true, 
                                normalizenames=true)

    for row in eachrow(defect_code_list)

        cvi_code = string(row[1])
        defect_code = row[2]
        survey_direction = row[3]
        calculation = row[4]
        lower_limit = row[5]  

        # convert the survey direction cross section code which is reported in the observ_defect_record
        xsp_dict = Dict("F" => "CL1", "R" => "CR1", "B" => "Both", "N/A" => "N")

        # convert the grouped DF to a standard DF
        #conv_section_df = DataFrame(section_df)
        #println("cvi_code ", cvi_code)
        returned_clusters = find_value_clusters(defect_df, cvi_code)
        #println(returned_clusters)
        #println(names(conv_section_df))
        returned_rows = find_rows_with_value(defect_df, cvi_code)
        
        defect_value = ""
        obval_code = ""
        obval_records = []
        defect_present = false

        #println("typeof returned_clusters :", typeof(returned_clusters))
        #println("returned_clusters :", returned_clusters)

        if !isempty(returned_clusters) # when there are returned clusters there is a defect to process
        # this should alway run as if there are no defects in the subsection the function will have already returned.

            obval_indicator = true
            
            #break the returned clusters vector into the seperate clusters when there is more than one and 
            #process them seperately

            for (idx, cluster) in enumerate(returned_clusters)
                
                #println("before select : ", names(defect_df))

                #println("passing to calculations: ",names(grid_defects))

                if calculation == "Length"
                    defect_value = fn_length_calc(defect_df, cluster, returned_rows)
                    obval_code = "P"
                    #println(calculation, "Length", defect_value)
                end

                if calculation == "Lateral"
                    defect_value = fn_lateral_calc(defect_df, cluster, returned_rows)
                    obval_code = "P"
                    #println(calculation, "Lateral  ", defect_value)
                end

                if calculation == "Count"
                    #println("returned_rows", returned_rows)
                    #println("returned cluster for count", cluster)
                    defect_value = fn_count_calc(defect_df, cluster, returned_rows)
                    obval_code = 'P' # was'V' until calculation found in spec see vol2, chap 7, pg12 !
                    #println(calculation, " Count ", defect_value)
                end

                if calculation ∉ ["Length", "Lateral", "Count"]
                    println( calculation, "calculation not accepted, check defect code info CSV")
                end

                # when the defect value is not a number don't bother processing it so set it to zero

                if defect_value isa Number
                    check_defect_value = defect_value
                else
                    check_defect_value = 0
                end

                # change the defect so there are only 2 decimal places
                new_defect_value = round(defect_value, digits=2)

                obval_option = categorise_value_ternary(new_defect_value)

                if obval_option != "0"
                    obval_defect_record = string("OBVAL\\1,", obval_option ,",", new_defect_value,",",obval_code,";\n")
                    push!(obval_records, obval_defect_record)
                    defect_present = true
                    obval_indicator = true
                end

                #println("obval_records", obval_records)

                #end    
            end

            #observation_number += 1
                #get the xsp_code from the dictionary
            xsp_code = xsp_dict[survey_direction]

            observ_directions = [xsp_code]
            new_items = ["CL1", "CR1"]

            if xsp_code == "Both"
                observ_directions = replace_and_expand(observ_directions, "Both", new_items)
            end

            println(observ_directions)

            for xsp_direction in observ_directions

                if length(obval_records) != 0

                    # there is a defect in the subsection so push the OBSERV record
                    observation_number += 1
                    observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,", xsp_direction,",",section_start_chainage,",",section_end_chainage,";\n")
                    push!(hmd_return_records, string(observ_defect_record))
                    push!(direction_processed_list, xsp_direction)  # add the xsp_code to the direction_list

                    #println("direction list ", direction_list)

                    if calculation != "Count"

                    # there might be more than one obval_defect_record so iterate through the vector
                        for record in obval_records
                        push!(hmd_return_records,string(record))
                        end
                    #end

                    else
                        # we are probably dealing with a 'count' so,
                        # count the number of obval records and create a single obval record with the count in it
                        defect_value = length(obval_records)

                        # the spec says multiply by 5 and express as a precentage of the section length, so
                        # spec at vol2, chapt7, pg12, table 4, Count  defects.
                        section_chainage = section_end_chainage - section_start_chainage
                        defect_value = defect_value * 5
                        defect_count_pc = defect_value/section_chainage * 100
                        obval_defect_record = string("OBVAL\\1,1,",defect_count_pc,",P;\n")
                        push!(hmd_return_records,string(obval_defect_record))

                            # clear the observ_defect_record and obval_defect_record for the next defect
                        observ_defect_record = ""
                        obval_defect_record = ""
                    end

                        #push!(hmd_return_records,string(obval_defect_record))
                    obval_record = true
                end # of obval records
            end
        end # defect_present

    end # <-- close the for defect loop

    unique_set = Set(direction_processed_list)
    #println("unique_set :", unique_set)
    unique_direction_list = collect(unique_set)
    #println("unique_direction_list ", unique_direction_list)

    for direction in ["CL1", "CR1"]
            
        if direction ∉ unique_direction_list
                #
            observation_number += 1
            observ_defect_record = string("OBSERV\\", observation_number, ",BUTS,235,", direction, ",", section_start_chainage, ",", section_end_chainage, ";\n")
            obval_defect_record = string("OBVAL\\1,3,100,P;\n")
            push!(hmd_return_records, observ_defect_record)
            push!(hmd_return_records, obval_defect_record)

        end
    end

    println("Finished processing defects for this subsection from ", section_start_chainage, " to ", section_end_chainage)

    hmd_return_strings = [String(item) for item in hmd_return_records]
    
    hmd_return = [(String(item)) for item in hmd_return_strings] 

    #println("end of process obsvervation records ")
    return hmd_return, observation_number
    #println(section_df)
end

