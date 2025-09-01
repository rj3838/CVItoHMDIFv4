using DataFrames

function process_observ_records(section_df::DataFrame, observation_number::Int16)
    # this is used to return the records
    hmd_return_records = []
    observ_defect_record = ""
    obval_defect_record = ""
    obval_indicator = false
    obval_record = false
    #observation_number = 0
    # The chainage for each observation will be
    section_start_chainage = section_df.StartCh[1]
    section_end_chainage = section_df.EndCh[1]

    #println("start ch : ", section_start_chainage)
    #println("end ch : ", section_end_chainage)

    #println("section names: ",names(section_df))
    #println(typeof(section_df))

    # check to see if the section_df contains only zeros in the defect columns
    # if it does then we can skip processing this section_df

    defect_df = DataFrame(section_df[:, 3:22])  # Adjust column indices as needed

    # convert all columns of defect_df to string
    string_defect_df = mapcols(x -> string.(x), defect_df)

    # now they are all srting convert them to numeric (Int64) that way it's easier to check for zeros

    for c in names(string_defect_df)
        try
            # Use a broadcasted parse to convert the column to a Float64
            defect_df[!, c] = parse.(Int64, string_defect_df[!, c])
        catch
            # If parsing fails, the column likely contains non-numeric data.
            # You may want to skip it or handle it differently.
            println("Could not convert column '$c' to numeric.")
        end
    end

    if all(x -> x == 0, Iterators.flatten(eachcol(defect_df))) # if every element in every column is zero !

        println("No defects found in this subsection from ", section_start_chainage, " to ", section_end_chainage)
        # if there are no defects in the subsection then we need to push a BUTS record with zero values
        #observation_number += 1
        for xsp_code in ["CL1", "CR1"]
            observation_number += 1
            observ_defect_record = string("OBSERV\\", observation_number, ",BUTS,235,", xsp_code, ",", section_start_chainage, ",", section_end_chainage, ";\n")
            obval_defect_record = string("OBVAL\\1,1,0,P,,;\n")
            push!(hmd_return_records, observ_defect_record)
            push!(hmd_return_records, obval_defect_record)
        end
        return hmd_return_records, observation_number
    end
    
    # this is used to check if any defects are present in the section
    defect_present = false
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

        #println(cvi_code, " ", defect_code, " ", survey_direction, " ", calculation, " ", lower_limit)

        # convert the grouped DF to a standard DF
        conv_section_df = DataFrame(section_df)
        #println("cvi_code ", cvi_code)
        returned_clusters = find_value_clusters(conv_section_df, cvi_code)
        
        #println(names(conv_section_df))
        returned_rows = find_rows_with_value(conv_section_df, cvi_code)
        
        defect_value = ""
        obval_code = ""
        obval_records = []
        defect_present = false
        #println("typeof returned_clusters :", typeof(returned_clusters))
        #println("returned_clusters :", returned_clusters)

        if !isempty(returned_clusters) # when there are returned clusters

            obval_indicator = true
            
            #break the returned clusters vector into the seperate clusters when there is more than one and 
            #process them seperately

            for (idx, cluster) in enumerate(returned_clusters)

                if calculation == "Length"
                    defect_value = fn_length_calc(conv_section_df, cluster, returned_rows)
                    obval_code = "P"
                    #println(calculation, "Length", defect_value)
                end

                if calculation == "Lateral"
                    defect_value = fn_lateral_calc(conv_section_df, cluster, returned_rows)
                    obval_code = "P"
                    #println(calculation, "Lateral  ", defect_value)
                end

                if calculation == "Count"
                    #println("returned_rows", returned_rows)
                    #println("returned cluster for count", cluster)
                    defect_value = fn_count_calc(conv_section_df, cluster, returned_rows)
                    obval_code = 'V'
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
                
                check_value ::Int64 = lower_limit

                #observation_number += 1
                
                    #println(typeof(defect_value), " value ", defect_value)
                new_defect_value = round(defect_value, digits=2)
                obval_defect_record = string("OBVAL\\$idx,1,",new_defect_value,",",obval_code,",,;\n")
                push!(obval_records, obval_defect_record)
                defect_present = true
                obval_indicator = true

                #println("obval_records", obval_records)

                #end    
            end

            # when there are obval_records  push the observ and obval records to the hmd_return_records

            if defect_present == true
                # there is at least one defect in the subsection so push the OBSERV record

                observation_number += 1
                #get the xsp_code from the dictionary
                xsp_code = xsp_dict[survey_direction]

                # there is no defect in the subsection so push the OBSERV record
                observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,", xsp_code,",",section_start_chainage,",",section_end_chainage,";\n")
                push!(hmd_return_records, string(observ_defect_record))
                println("pushing observ record ", observ_defect_record)
                #println("pushing observ record ", observ_defect_record)
                if calculation != "Count"

                        # there might be more than one obval_defect_record so iterate through the vector
                    for record in obval_records
                        push!(hmd_return_records,string(record))
                    end

                else
                        # we are probably dealing with a 'count' so,
                        # count the number of obval records and create a single obval record with the count in it
                    defect_value = length(obval_records)
                    obval_defect_record = string("OBVAL\\1,1,",defect_value,",",obval_code,",,;\n")
                    push!(hmd_return_records,string(obval_defect_record))
                    #end
                    # clear the observ_defect_record and obval_defect_record for the next defect
                    observ_defect_record = ""
                    obval_defect_record = ""

                    #push!(hmd_return_records,string(obval_defect_record))
                    obval_record = true
                end
            end
        end
        # if there are no obval records for this defect code then we need to push an OBSERV buts record
        #if obval_record == false
        #    println("No defects found for code ", cvi_code)
        #    defect_count += 1
        #     observation_number += 1
        #     # get the xsp_code from the dictionary for both directions
        #     for xsp_code in ["CL1", "CR1"]
        #         observation_number += 1
        #         observ_defect_record = string("OBSERV\\", observation_number, ",BUTS,235,", xsp_code, ",", section_start_chainage, ",", section_end_chainage, ";\n")
        #         obval_defect_record = string("OBVAL\\1,1,0,P,,;\n")
        #         push!(hmd_return_records, observ_defect_record)
        #         push!(hmd_return_records, obval_defect_record)
        #     end
        #     observ_defect_record = ""
        #     obval_defect_record = ""
        #     obval_indicator = false
        #end
        # if defect_count < size(section_df,1)
        #     observation_number += 1
        #     # get the xsp_code from the dictionary for both directions
        #     for xsp_code in ["CL1", "CR1"]
        #         observation_number += 1
        #         observ_defect_record = string("OBSERV\\", observation_number, ",BUTS,235,", xsp_code, ",", section_start_chainage, ",", section_end_chainage, ";\n")
        #         obval_defect_record = string("OBVAL\\1,1,0,P,,;\n")
        #         push!(hmd_return_records, observ_defect_record)
        #         push!(hmd_return_records, obval_defect_record)
        #     end
        #     observ_defect_record = ""
        #     obval_defect_record = ""
        #     obval_indicator = false
        # end
    end # <-- close the for loop

    hmd_return_strings = [String(item) for item in hmd_return_records]
    
    hmd_return = [(String(item)) for item in hmd_return_strings] 
    #println("hmd_return ", hmd_return)
    #return 99, observation_number
    #
    return hmd_return, observation_number
    
    #println(section_df)
   
end
