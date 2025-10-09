using DataFrames

function process_observ_records(section_df::DataFrame, observation_number::Int16)
    #println("starting process obsvervation records for section: ", section_df.SectionID[1])
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

    println("Start of processing subsection from $section_start_chainage to $section_end_chainage")

    #println("start ch : ", section_start_chainage)
    #println("end ch : ", section_end_chainage)

    #println("section names: ",names(section_df))
    #println(typeof(section_df))

    # this list is used to track which directions have been processed in the section_df so we can create BUTS records if needed
    # for directions without defects 
    direction_list = ["CL1", "CR1"]

    # check to see if the section_df contains only zeros in the defect columns
    # if it does then we can skip processing this section_df

    defect_df = DataFrame(section_df[:, 3:22])  # Adjust column indices as needed

    # convert all columns of defect_df to string
    string_defect_df = mapcols(x -> string.(x), defect_df)

    # now they are all strting convert them to numeric (Int64) that way it's easier to check for zeros

    for c in names(string_defect_df)
        try
            # Use a broadcasted parse to convert the column to a Float64
            defect_df[!, c] = parse.(Int64, string_defect_df[!, c])
        catch
            # If parsing fails, the column likely contains non-numeric data.
            # You may want to skip it or handle it differently.
            #println("Could not convert column '$c' to numeric.")
        end
    end
    
    # this is used to check if any defects are present in the section
    defect_present = false

    # read the defect code list

    defect_code_list = CSV.read("CVI_Defect_code_info.csv", 
                                DataFrame; delim=',', 
                                header=true, 
                                normalizenames=true)

    # convert the survey direction cross section code which is reported in the observ_defect_record
    xsp_dict = Dict("F" => "CL1", "R" => "CR1", "B" => "Both", "N/A" => "N")

    for row in eachrow(defect_code_list)

        cvi_code = string(row[1])
        defect_code = row[2]
        survey_direction = row[3]
        calculation = row[4]
        lower_limit = row[5]  

        # convert the grouped DF to a standard DF
        conv_section_df = DataFrame(section_df)

        #println("cvi_code ", cvi_code)
        returned_clusters = find_value_clusters(conv_section_df, cvi_code)
        
        #println(names(conv_section_df))
        returned_rows = find_rows_with_value(conv_section_df, cvi_code)
        
        # defect_value = ""
        # obval_code = ""
        obval_records = []
        # defect_present = false
        #println("typeof returned_clusters :", typeof(returned_clusters))
        #println("returned_clusters :", returned_clusters)

        if !isempty(returned_clusters) # when there are no returned clusters then empty the direction_list

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
            end # end of returned clusters loop

            # when there are obval_records  push the observ and obval records to the hmd_return_records

            #if defect_present == true
            if direction_list == ["CL1", "CR1"]
            # there is at least one defect in the subsection so push the OBSERV record

                observation_number += 1
                #get the xsp_code from the dictionary
                xsp_code = xsp_dict[survey_direction]

                if xsp_code == "Both"
                    # if the defect is reported in both directions then we need to push two observ records
                    # one for each direction
                    for dir_xsp in ["CL1", "CR1"]
                        observation_number += 1
                        observ_defect_record = string("OBSERV\\", observation_number, ",",defect_code,",235,", dir_xsp, ",",section_start_chainage,",",section_end_chainage,";\n")
                        push!(hmd_return_records, string(observ_defect_record))
                        append!(hmd_return_records, obval_records)
                    end
                    # remove both directions from the direction_list as they have been processed
                    filter!(x -> x != "CL1" && x != "CR1", direction_list)

                elseif xsp_code == "CL1"
                    observ_defect_record = string("OBSERV\\", observation_number, ",",defect_code,",235,", xsp_code, ",",section_start_chainage,",",section_end_chainage,";\n")
                    push!(hmd_return_records, string(observ_defect_record))
                    append!(hmd_return_records, obval_records)
                    # remove CL1 from the direction_list as it has been processed
                    filter!(x -> x != "CL1", direction_list)
                elseif xsp_code == "CR1"
                    observ_defect_record = string("OBSERV\\", observation_number, ",",defect_code,",235,", xsp_code, ",",section_start_chainage,",",section_end_chainage,";\n")
                    push!(hmd_return_records, string(observ_defect_record))
                    append!(hmd_return_records, obval_records)
                    # remove CR1 from the direction_list as it has been processed
                    filter!(x -> x != "CR1", direction_list)
                else
                    println("xsp_code not recognised ", xsp_code)
                end
                
            else
                
            #if !isempty(direction_list)
                println("directions without defects ", direction_list)
            
                # if there are directions without defects then we need to push a BUTS record for each direction
                # there should never be two directions without defects as that would have been caught by the
                # all zero defect check at the start of the function

                for direction_code in direction_list
                    observation_number += 1
                    observ_defect_record = string("OBSERV\\", observation_number, ",BUTS,235,", direction_code, ",", section_start_chainage, ",", section_end_chainage, ";\n")
                    obval_defect_record = string("OBVAL\\1,1,0,P,,;\n")
                    push!(hmd_return_records, observ_defect_record)
                    push!(hmd_return_records, obval_defect_record)
                    println("direction list ", direction_list, " removing ", direction_code)
                    filter!(x -> x != direction_code, direction_list)
                    println("direction list ", direction_list)
                end
            end # of empty direction list
        end #isempty direction_list

        observ_defect_record = ""
        obval_defect_record = ""
        obval_indicator = false
            
        end # there were returned clusters to process

        
        # end #isempty direction_list
     # <-- close the for defect row loop

    # end #isempty direction_list

    println("Finished processing defects for this subsection from $section_start_chainage to $section_end_chainage")

    hmd_return_strings = [String(item) for item in hmd_return_records]
    
    hmd_return = [(String(item)) for item in hmd_return_strings] 
    #println("hmd_return ", hmd_return)
    #return 99, observation_number
    #
    #println("end of process obsvervation records ")
    #return hmd_return, observation_number
    #end of defect row

    #println("end of process obsvervation records ")
    return hmd_return, observation_number
    #println(section_df)
   
end
