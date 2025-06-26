#This program is written Julia.
#
# The purpose is to read a Chartcrack grid from a CVI survey and produce a HMD for eventusl upload to a PMS

# to be added 
#Select file to open

using NativeFileDialog
using FilePathsBase
using CSV
using DataFrames
using DataFramesMeta

include("ClusterIdentification2.jl")
include("cvi_calculations.jl")
include("update_grid_with_section_2.jl")
include("Section_length.jl")
include("read_grid.jl")
include("fn_hmd_cvi_data_records.jl")
include("find_rows_with_value.jl")
include("create_survey_name.jl")
include("open_route_file.jl")
include("open_section_file.jl")
include("build_main_df.jl")
include("build_hmdif_header_block.jl")
include("process_combined_data.jl")
include("process_section_records.jl")
include("correct_split_sections.jl")
include("merge_split_section.jl")
include("process_observ_records.jl")
include("hmd_tail_records.jl")
include("fn_lateral_calc.jl")

function fn_gdf_iterate(gdf_passed)

    println("calling section process")
    [section_process(i) for i in gdf_passed]

end

function section_process(section_df::SubDataFrame{DataFrame, DataFrames.Index, Vector{Int64}})
    println("from section_process")
    section = section_df.SectionID[1]
    section_nr =section_df.sectionNr[1]
    start_chainage = first(section_df.Chainage)
    last_chainage = last(section_df.Chainage)
    length = last_chainage - start_chainage
    survey_direction = section_df.Direction[1]
    println("section ", section, " section number ", section_nr," start ", start_chainage, " last ", last_chainage, " section length ", length)
    hmd_return_records  = String[]
   

    # section template for HMDIF is
    # SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;

    # building SECTION record
    hmd_section_record = string("SECTION\\", section, ",", section_nr, ",F,", survey_direction, ",", string(round(length,digits=2)), ",,,,,;\n") 
    #println("sectoin ",hmd_section_record)
    push!(hmd_return_records,string(hmd_section_record))
    # defing the output records for the HMDIF as empty strings
    observ_defect_record = ""
    obval_defect_record = ""
    # this is used to return the records
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
        
        #println(cvi_code, " ", defect_code, " ", survey_direction, " ", calculation, " ", lower_limit)
    
    #observ and obval templates are :
    #OBSERV\\NUMBER,DEFECT,VERSION,XSECT,SCHAIN,ECHAIN;"
    #OBVAL\\PARM,OPTION,VALUE,PERCENT;
    
    #BNAS - code 19 is Not assesed
    #cvi_code = "19"
    # how many rows contain a 19
    #println("typeof", typeof(find_rows_with_value(section_df, cvi_code)))

        # convert the grouped DF to a standard DF
        conv_section_df = DataFrame(section_df)
        #println("cvi_code ", cvi_code)
        returned_clusters = find_value_clusters(conv_section_df, cvi_code)
        println("returned_clusters type ", typeof(returned_clusters))
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

        #println("Defect check")
        #println(typeof(defect_value), " ", defect_value)

        # when the defect value is not a number don't bother processing it so set it to zero

        if defect_value isa Number
            check_defect_value = defect_value
        else
            check_defect_value = 0
        end
        
        check_value ::Int64 = lower_limit
        #println("check_value ", check_value, " defect_value ", defect_value)

        # for some defects the defect value must exceed a metre.

        if check_defect_value > check_value #|| (!isempty(defect_value))

            observation_number += 1
            defect_present = true
            observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,",minimum(conv_section_df.Chainage),",",maximum(conv_section_df.Chainage),";\n")
            obval_defect_record = string("OBVAL\\1,1,",round(defect_value, digits=2),",",obval_code,",,;\n")
            #println("observ_defect_record ",observ_defect_record)
            #println("obval_defect_record ",obval_defect_record)
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
    
end

function fn_build_hmdif(grid_data, survey_name, route_data)

# Build the output HMDIF
# header is standard
    HMDIF_out = String[] # empty list/array
    line1 = "HMSTART ukPMS 001  ; , \\\n"
    line2 = "TSTART;\n"
    line3 = "SURVEY\\TYPE,VERSION,NUMBER,NAME,SUBSECT,CWXSPUSED,OFFCWXSPUSED;\n"
    line4 = "SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;\n"
    line5 = "OBSERV\\NUMBER,DEFECT,VERSION,XSECT,SCHAIN,ECHAIN;\n"
    line6 = "OBVAL\\PARM,OPTION,VALUE,PERCENT;\n"
    line7 = "TEND\\7;\n"
    line8 = "DSTART;\n"

    push!(HMDIF_out, line1,
                    line2,
                    line3,
                    line4,
                    line5,
                    line6,
                    line7,
                    line8)

    #survey_record = "SURVEY\\CVI,235,5,$survey_name,,,;\n"
    #push!(HMDIF_out,survey_record)
           
    #HMDIF_out = split(HMDIF_header, '\r')

    println(HMDIF_out)

    # combine the route and the grid data so it will only contain sections from the survey(s) of interest.

    #route_df = route_csv_to_df_processing(route_data)
    #println("grid_data names",names(grid_data))
    grid_data_with_route = update_section(grid_data, route_data)
    #println(grid_data_with_route)
    # building the data in a seperate function

    #println("grid_data names + route",names(grid_data_with_route))

    data_out = fn_hmd_cvi_data_records(grid_data_with_route)

    #println("out",data_out)
    data_out = [join(inner_vector, "") for inner_vector in data_out]
    append!(HMDIF_out, data_out)
    #println("typeof HMD_out",typeof(HMDIF_out))

    #dend_count = length(data_out)
    #println(typeof(data_out), length(data_out))
    #dend_count = count('\n', data_out)
    # remove empty (0 length) vectors in the HMD_out
    filter!(!isempty, HMDIF_out)

    # function count_newlines(strings::Vector{String})
    #     newline_count = 0
    #     for str in strings
    #       newline_count += count('\n', str)
    #     end
    #     return newline_count
    #   end
    #  HMDIF_out is a vector of strings, each possibly containing \n
    HMDIF_out = collect(Iterators.flatten(split.(HMDIF_out, '\n')))
    # then remove the empty occurrences (shouldn't be any, but...)
    HMDIF_out = filter(!isempty, HMDIF_out)
    # add a newline chatecter to the end of each string
    HMDIF_out = [string(item, "\n") for item in HMDIF_out]
    #HMDIF_count = count_newlines(HMDIF_out)
    #println("typeof hmd_out ",HMDIF_out)
    HMDIF_count = size(HMDIF_out)[1]
    #println("hmdif_count ", HMDIF_count)
    dend_count = Int(HMDIF_count) - 8 
    # 8 is the number of data lines in the data including the DSTART + DEND

    #println(dend_count)
    #DEND_string = raw"DEND\\" + string(dend_value) + raw";"
    DEND_string = "DEND\\$dend_count;\n"
    push!(HMDIF_out, DEND_string)
    #println(HMDIF_out)
    # HMEND is the length of HMDIF_out plus 1 (needs to include the HMEND record)
    
    HMDIF_count = size(HMDIF_out)[1] + 1
    HMEND_string = "HMEND\\$HMDIF_count;"
    push!(HMDIF_out, HMEND_string)
    return HMDIF_out
end

#start of main

function main()
    println("CVI to HMDIF")
    println("Select a CVI grid file to convert to HMDIF")

# Open the file in read mode
# reverse the commenting to test file selection
#grid_file_name = pick_file()
#println(grid_file_name)
#file = open(grid_file_name, "r")
#file = open("Zone1_Route1.grd", "r")

    grid_file_name = "AdHoc-Rickney.grd"
    #grid_file_name = "Test Grid 3.grd"

    # create the survey name and survey file name and read the grid

    #survey_output_file, survey_ID = create_survey_name(grid_file_name)

    #println("survey name ", survey_ID)
    #println("survey output file ", survey_output_file)     

    grid_df = read_data_grid(grid_file_name)

    # change the filetype to be csv and read the route file

    route_file_name = string(replace(grid_file_name, ".grd" => ".csv"))

    route_df = open_route_file(route_file_name)

    section_file_name = "East Sussex Sections 2025.csv"

    # read the section file
    section_df = open_section_file(section_file_name)

    #println("grid data headers ", names(grid_df))
    #println("route data headers ", names(route_df))
    #println("section data headers ", names(section_df))

    # take the three data frames and merge/join them to produce a single dataframe 
    # that can be processed by survey, section and observation.

    combined_df  = build_main_df(grid_df, route_df, section_df)

    #All the needed data is now in the combined_df

    #create the survey name and survey file name
    survey_output_file, survey_ID = create_survey_name(grid_file_name)
    #println("survey name ", survey_ID)
    #println("survey output file ", survey_output_file)

    # create the HMD header block

    HMD_output = build_hmdif_header_block(survey_ID)

    #println("HMD header block ", HMD_output)

    network_gdf = DataFrames.groupby(combined_df, :Network)

    for gdf in network_gdf
        println("Network ", gdf.Network[1])
        # if there is nothing in the network (gdf length is 0)
        # process the next gdf
        if nrow(gdf) == 0
            continue
        end
        #println("gdf ", gdf)
        #println("gdf names ", names(gdf))
        #println("gdf length ", nrow(gdf))
        #println("gdf type ", typeof(gdf))
        #println("gdf section ID ", gdf.SectionID[1])
        #println("gdf section number ", gdf.sectionNr[1])
        #println("gdf start chainage ", first(gdf.Chainage))
        #println("gdf last chainage ", last(gdf.Chainage))
        #println("gdf length ", last(gdf.Chainage) - first(gdf.Chainage))
        standard_df = DataFrame(gdf)
        returned_records = process_combined_data(standard_df, survey_ID)
        #returned_records = join(returned_records)
        #println(typeof(returned_records), " ", length(returned_records), " records returned from process_combined_data")
        #println(typeof(HMD_output), " ", length(HMD_output))
        append!(HMD_output, returned_records)
    end

   

    # but we need to clean up the data a bit more, the data where there is a diversion off onto a different section
    # which then returns to the original section.
    # the main chainage doesn't change as it is the distance into the survey grid but startC, endCh and length needs
    # to twidled a bit.

    #corrected_df = correct_diverted_sections(combined_df)



    #rename!(route_data, [col => replace(col, " " => "_") for col in names(route_data)])
#     println("replaced route data names ", names(route_data))
#     HMD_output = fn_build_hmdif(grid_data, survey_ID, route_data)
#     #println("survey name ", survey_name)

#println(typeof(HMD_output))

#println(HMD_output)

filter!(s -> !isempty(s), HMD_output)

hmd_tail = hmd_tail_records(HMD_output)

    #println("hmd_tail ", hmd_tail)

# add the tail records to the HMD output
append!(HMD_output, hmd_tail)

#println("HMD output type ", typeof(HMD_output))

# write the HMD output to a file
#println("Writing HMDIF output to file ", survey_output_file)



open(survey_output_file, "w") do file
     for line in HMD_output
         if length(line) > 3
            write(file, String(line))
         end
     end
end

    # if abspath(PROGRAM_FILE) == @__FILE__
    #     main()
    # end

    # # end of main
end

main()
