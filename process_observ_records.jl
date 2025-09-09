using DataFrames

function process_observ_records(section_df::DataFrame, observation_number::Int16)
    # this is used to return the records
    hmd_return_records = []
    observ_defect_record = ""
    obval_defect_record = ""
    obval_indicator = false
    # The chainage for each observation will be
    section_start_chainage = section_df.StartCh[1]
    section_end_chainage = section_df.EndCh[1]

    #println("start ch : ", section_start_chainage)
    #println("end ch : ", section_end_chainage)
    
    # start the observation counter for this section
    #observation_number = 0
    # this is used to check if any defects are present in the section
    defect_present = false
    # read the defect code list

    defect_code_list = CSV.read("CVI_Defect_code_info.csv", 
                                DataFrame; delim=',', 
                                header=true, 
                                normalizenames=true)
    
    #println("defect_list size ",size(defect_code_list,1)

    obval_indicator = false

    for row in eachrow(defect_code_list)

        cvi_code = string(row[1])
        defect_code = row[2]
        survey_direction = row[3]
        calculation = row[4]
        lower_limit = row[5]

        # convert the survey direction cross section code which is reported in the observ_defect_record
        xsp_dict = Dict("F" => "CL1", "R" => "CR1", "B" => "Both", "N/A" => "N")

        #println(cvi_code, " ", defect_code, " ", survey_direction, " ", calculation, " ", lower_limit)

        # the observ record is the same for all value clusters found in a section (but only push it at the end !)
        #observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,,",section_start_chainage,",",section_end_chainage,";\n")
    
        # convert the grouped DF to a standard DF
        conv_section_df = DataFrame(section_df)
        #println("cvi_code ", cvi_code)
        returned_clusters = find_value_clusters(conv_section_df, cvi_code)
        #println("returned_clusters ", returned_clusters)
        #println(names(conv_section_df))
        returned_rows = find_rows_with_value(conv_section_df, cvi_code)
        
        defect_value = ""
        obval_code = ""
        obval_records = []
        defect_present = false
        #println("typeof returned_clusters :", typeof(returned_clusters))
        #println("returned_clusters :", returned_clusters)

        if !isempty(returned_clusters)

            obval_indicator = true

            #println("returned_clusters with something in ?", returned_clusters)

            #println("cvi_code: ", cvi_code, )
            #observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,,",section_start_chainage,",",section_end_chainage,";\n")

            #println("returned_clusters ", returned_clusters)
            
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
                
                #check_value ::Int64 = lower_limit

                #observation_number += 1
                
                    #println(typeof(defect_value), " value ", defect_value)
                new_defect_value = round(defect_value, digits=2)
                    #observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,,",section_start_chainage,",",section_end_chainage,";\n")
                    #obval_defect_record = string("OBVAL\\1,1,",round(defect_value, digits=2),",",obval_code,",,;\n")
                    #observ_defect_record = string("OBSERV\\",frame_number,",",defect_code,",235,",minimum(conv_section_df.Chainage),",",maximum(conv_section_df.Chainage),";\n")
                obval_defect_record = string("OBVAL\\$idx,1,",new_defect_value,",",obval_code,",,;\n")
                push!(obval_records, obval_defect_record)
                defect_present = true
                obval_indicator = true

                #end    
            end

            if obval_indicator == true

                observation_number += 1
                #get the xsp_code from the dictionary
                xsp_code = xsp_dict[survey_direction]

                # there is a defect in the subsection so push the OBSERV record
                observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,", xsp_code,",",section_start_chainage,",",section_end_chainage,";\n")
                push!(hmd_return_records,string(observ_defect_record))

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
        if obval_indicator == false #|| !defect_present
            observation_number += 1
            # get the xsp_code from the dictionary for both directions
            for xsp_code in ["CL1", "CR1"]
                observ_defect_record = string("OBSERV\\", observation_number, ",BUTS,235,", xsp_code, ",", section_start_chainage, ",", section_end_chainage, ";\n")
                obval_defect_record = string("OBVAL\\1,1,0,P,,;\n")
                push!(hmd_return_records, observ_defect_record)
                push!(hmd_return_records, obval_defect_record)
            end
            observ_defect_record = ""
            obval_defect_record = ""
            obval_indicator = false
        end
    end # <-- close the for loop

    hmd_return_strings = [String(item) for item in hmd_return_records]
    
    hmd_return = [(String(item)) for item in hmd_return_strings] 

    #return 99, observation_number
    #
    return hmd_return, observation_number
    
    #println(section_df)
   
end
