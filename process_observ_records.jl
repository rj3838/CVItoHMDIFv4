function process_observ_records(section_df::DataFrame, frame_number::Int)
    # this is used to return the records
    hmd_return_records = []
    observ_defect_record = ""
    obval_defect_record = ""
    
    # start the observation counter for this section
    observation_number = 0
    # this is used to check if any defects are present in the section
    defect_present = false
    # read the defect code list

    defect_code_list = CSV.read("CVI_Defect_code_info.csv", DataFrame; delim=',', header=true, normalizenames=true)
    #defect_list_length = size(defect_code_list,1)

    for row in eachrow(defect_code_list)

        cvi_code = string(row[1])
        defect_code = row[2]
        survey_direction = row[3]
        calculation = row[4]
        lower_limit = row[5]
        
        println(cvi_code, " ", defect_code, " ", survey_direction, " ", calculation, " ", lower_limit)
    
    #observ and obval templates are :
    #OBSERV\\NUMBER,DEFECT,VERSION,XSECT,SCHAIN,ECHAIN;"
    #OBVAL\\PARM,OPTION,VALUE,PERCENT;
    
    #BNAS - code 19 is Not assesed
    #cvi_code = "19"
    # how many rows contain a 19
    #println("typeof", typeof(find_rows_with_value(section_df, cvi_code)))

        # convert the grouped DF to a standard DF
        conv_section_df = DataFrame(section_df)
        println("cvi_code ", cvi_code)
        returned_clusters = find_value_clusters(conv_section_df, cvi_code)
        println("returned_clusters ", returned_clusters)
        #println(names(conv_section_df))
        returned_rows = find_rows_with_value(conv_section_df, cvi_code)
        
        defect_value = ""
        obval_code = ""
        
        if !isempty(returned_clusters)

            #global observation_number += 1

            if calculation == "Length"
                defect_value = fn_length_calc(conv_section_df, returned_clusters, returned_rows)
                obval_code = "P"
                println(calculation, "Length", defect_value)
            end

            if calculation == "Lateral"
                defect_value = fn_lateral_calc(conv_section_df, returned_clusters, returned_rows)
                obval_code = "P"
                println(calculation, "Lateral  ", defect_value)
            end

            if calculation == "Count"
                defect_value = fn_count_calc(conv_section_df, returned_clusters, returned_rows)
                obval_code = 'V'
                println(calculation, "Count ", defect_value)
            end

            if calculation ∉ ["Length", "Lateral", "Count"]
                println( calculation, "calculation not accepted, check defect code info CSV")
            end

        end

        println("Defect check")
        println(typeof(defect_value), " ", defect_value)

        # when the defect value is not a number don't bother processing it so set it to zero

        if defect_value isa Number
            check_defect_value = defect_value
        else
            check_defect_value = 0
        end
        
        check_value ::Int64 = lower_limit
        println("check_value ", check_value, " defect_value ", defect_value)

        # for some defects the defect value must exceed a metre.

        if check_defect_value > check_value #|| (!isempty(defect_value))

            observation_number += 1
            defect_present = true
            observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,",minimum(conv_section_df.Chainage),",",maximum(conv_section_df.Chainage),";\n")
            obval_defect_record = string("OBVAL\\1,1,",round(defect_value, digits=2),",",obval_code,",,;\n")
            println("observ_defect_record ",observ_defect_record)
            println("obval_defect_record ",obval_defect_record)
        # else
        #     println("Defect value ", defect_value, " is less than the lower limit ", lower_limit, " or no defect so not recorded")
        #     observ_defect_record = string("OBSERV\\",observation_number,",BNAS,235,",minimum(conv_section_df.Chainage),",",maximum(conv_section_df.Chainage),";\n")
        #     obval_defect_record = string("OBVAL\\1,1,",defect_value,",",obval_code,",,;\n")  

        end

        if defect_present
            push!(hmd_return_records,string(observ_defect_record))
            push!(hmd_return_records,string(obval_defect_record))
            # clear the observ_defect_record and obval_defect_record for the next defect
            observ_defect_record = ""
            obval_defect_record = ""
        # else
        #     observ_defect_record = string("OBSERV\\",observation_number,",BUTS,235,",minimum(conv_section_df.Chainage),",",maximum(conv_section_df.Chainage),";\n")
        #     obval_defect_record = string("OBVAL\\1,1,",defect_value,",",obval_code,",,;\n")
        #     push!(hmd_return_records,string(observ_defect_record))
        #     push!(hmd_return_records,string(obval_defect_record)) 
        end
    

    # when defect is not found the section is still recorded but with a BUTS code
    if !defect_present
        observation_number += 1
        observ_defect_record = string("OBSERV\\",observation_number,",BUTS,235,",minimum(section_df.Chainage),",",maximum(section_df.Chainage),";\n")
        obval_defect_record = string("OBVAL\\1,1,0,P,,;\n")
        push!(hmd_return_records,string(observ_defect_record))
        push!(hmd_return_records,string(obval_defect_record))
    end

    hmd_return_strings = [String(item) for item in hmd_return_records]
    
    hmd_return = [(String(item)) for item in hmd_return_strings] 

    return hmd_return
    
    #println(section_df)
    
    end # <-- Add this to close the for loop

end