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
#import .ClusterIdentification

#import find_value_clusters
#import fn_cluster_ident

function fn_gdf_iterate(gdf_passed)

    println("calling section process")
    [section_process(i) for i in gdf_passed]

end

# Function to find rows containing a specific value

   # find_rows_with_value(df::DataFrame, value::Any)


function find_rows_with_value(section_df::DataFrame, cvi_code::String)
    # remove the sectionID, Chainage and sectionNr columns as the string used for the cvi code can occur in 
    # those columns.
    #print("find_rows_with_value")
     
    rows_with_value = findall(row -> any(x -> x == cvi_code, row), eachrow(select(section_df, Not([:SectionID, :Chainage]))))

    #p#rintln(typeof((section_df[rows_with_value, :]))) #0
    #println("typeof ",typeof(rows_with_value))
    row_number = size(section_df[rows_with_value, :],1)
    #println(row_number)
    #filter(row -> any(x -> x == value, row), eachrow(df))
    #@where(df, findall(x -> x == value))
    #print("exit find_rows_with_value")
    return row_number
end

function section_process(section_df::SubDataFrame{DataFrame, DataFrames.Index, Vector{Int64}})
    println("from section_process")
    section = section_df.SectionID[1]
    section_nr =section_df.sectionNr[1]
    start_chainage = first(section_df.Chainage)
    last_chainage = last(section_df.Chainage)
    length = last_chainage - start_chainage
    println("section ", section, " section number ", section_nr," start ", start_chainage, " last ", last_chainage, " section length ", length)
    hmd_return_records  = String[]
    # section template for HMDIF is
    # SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;
    # building SECTION record
    hmd_section_record = string("SECTION\\", section, ",", section_nr, ",F,F,,", string(length),",,,,,;\n") 
    #println("sectoin ",hmd_section_record)
    push!(hmd_return_records,string(hmd_section_record))

    # start the observation counter for this section
    observation_number = 0

    # read the defect code list

    defect_code_list = CSV.read("CVI_Defect_code_info.csv", DataFrame)
    defect_list_length = size(defect_code_list,1)

    for row in eachrow(defect_code_list)

        cvi_code = string(row[1])
        defect_code = row[2]
        survey_direction = row[3]
        calculation = row[4]
        lower_limit = row[5]
        
        println(cvi_code, " ", defect_code, " ", survey_direction, " ", calculation)
    
    #observ and obval templates are :
    #OBSERV\\NUMBER,DEFECT,VERSION,XSECT,SCHAIN,ECHAIN;"
    #OBVAL\\PARM,OPTION,VALUE,PERCENT;
    
    #BNAS - code 19 is Not assesed
    #cvi_code = "19"
    # how many rows contain a 19
    #println("typeof", typeof(find_rows_with_value(section_df, cvi_code)))

        # convert the grouped DF to a standard DF
        conv_section_df = DataFrame(section_df)
        returned_clusters = find_value_clusters(conv_section_df, cvi_code)
        returned_rows = find_rows_with_value(conv_section_df, cvi_code)
        
        defect_value = ""
        obval_code = ""
        
        
        #println("returned_clusters ", returned_clusters)
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

        # for some defects the defect value must exceed a metre.

        if check_defect_value > check_value #|| (!isempty(defect_value))

            observation_number += 1

            observ_defect_record = string("OBSERV\\",observation_number,",",defect_code,",235,",minimum(conv_section_df.Chainage),",",maximum(conv_section_df.Chainage),";\n")
            obval_defect_record = string("OBVAL\\1,1,",defect_value,",",obval_code,",,;\n")
            
        else
            println("Defect value ", defect_value, " is less than the lower limit ", lower_limit, " or no defect so not recorded")
            observ_defect_record = string("OBSERV\\",observation_number,",BNAS,235,",minimum(conv_section_df.Chainage),",",maximum(conv_section_df.Chainage),";\n")
            obval_defect_record = string("OBVAL\\1,1,",defect_value,",",obval_code,",,;\n")  

        end
        push!(hmd_return_records,string(observ_defect_record))
        push!(hmd_return_records,string(obval_defect_record))
    end
    hmd_return_strings = [String(item) for item in hmd_return_records]
    #println("boo",hmd_return_strings)
       
    hmd_return = [(String(item)) for item in hmd_return_strings]   
    return hmd_return
    
    #println(section_df)
    
end


function fn_hmd_cvi_data_records(grid_data)

    #this function needs the grid data to be modified before with the route information beforehand
    # in this way the grid data will only contain the relevant data for the survey


    # drop rows with missing fields, this drops the dummy OSGR data at the end of the file.
    dropmissing!(grid_data)

    # rename the 'Section ID' by removing the spaces as it's easier to deal with.
    #rename!(grid_data, Symbol("Section ID") => :SectionID)
    
    # convert the chainage to a float then
    # create a new column using flooring division on the Chaniage to produce a 'new' section number each 20m
    # then convert it to a string.
    #transform!(grid_data, :Chainage => ByRow(x -> parse(Float64, x)) => :Chainage)
    @rtransform!(grid_data, :sectionNr = fld1(:Chainage, 20))
    @rtransform!(grid_data, :sectionNr = string(round(Int, :sectionNr)))

    # Section Id and sectionNr can now be used to create a grouped data frame.
    #gdf_grid_data = groupby(grid_data, [:SectionID, :sectionNr])
    gdf_grid_data = groupby(grid_data, [:SectionID, :StartCh])

    # now for each grouped DF create records for section + observ + obval 

    #println(gdf_grid_data) # just to check

    gdf_data_records = fn_gdf_iterate(gdf_grid_data)

    # tidy up the data records so they are just a string.
    #[push!(gdf_data_records, string(i)) for i in gdf_data_records]

    # don't forget to return the data record strings.
    #print(gdf_data_records)

    return gdf_data_records
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

    survey_record = "SURVEY\\CVI,235,5,$survey_name,,,;\n"
    push!(HMDIF_out,survey_record)
    #println(HMDIF_out)
    #println(typeof(HMDIF_out))
    #println(size(HMDIF_out))       
    #HMDIF_out = split(HMDIF_header, '\r')

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

    # remove empty (0 length) vectors in the HMD_out
    filter!(!isempty, HMDIF_out)

    function count_newlines(strings::Vector{String})
        newline_count = 0
        for str in strings
          newline_count += count('\n', str)
        end
        return newline_count
      end

    HMDIF_count = count_newlines(HMDIF_out)
    #println(size(HMDIF_out))
    #HMDIF_count = size(HMDIF_out)[1]
    println("hmdif_count ", HMDIF_count)
    dend_count = Int(HMDIF_count) + 9
    #println(dend_count)
    #DEND_string = raw"DEND\\" + string(dend_value) + raw";"
    DEND_string = "DEND\\$dend_count;\n"
    push!(HMDIF_out, DEND_string)
    #println(HMDIF_out)
    # print("""DEND\\""", dend_value)

# HMEND is the length of HMDIF_out plus 9 (headers + HMSTART record + HMEND record)
    #print("HMDIF size",size(HMDIF_out))
    #HMDIF_count = size(HMDIF_out)[1] + 9
    HMDIF_count= dend_count + 9
    HMEND_string = "HMEND\\$HMDIF_count;"
    push!(HMDIF_out, HMEND_string)
    return HMDIF_out
end

function create_survey_name(grid_file_name)
    # open the grid_file_name in read mode
    grid_file = open(grid_file_name, "r")

    # Read the first line and get the original filename from item

    #read the first line from the grid_file_stream
    #grid_file_stream = open(grid_file_name, "r")
    #read the first line

    first_line = readline(grid_file)
    close(grid_file)

    # Print the first line
    println(first_line)

#Use the string after the word 'file' as the survey name

    survey_name = split(first_line, r"^.+file ")[:2]

    print("survey_name", survey_name)

# replace the spaces with an underscore
    survey_name = string(replace(survey_name, " " => "_"))
    # append .hmd to the survey name
    survey_hmd_file = string(survey_name, ".HMD")
    #survey_output_file = string(replace(survey_name, " " => "_") * ".HMD")

    println("survey name is ",survey_name)
    println("output file is ", survey_hmd_file)

    return survey_hmd_file, survey_name

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

    grid_file_name = "Zone1_Route1.grd"

# create the survey name and survey file name and read the grid

    survey_output_file, survey_ID = create_survey_name(grid_file_name)

    #println("survey name ", survey_ID)
    #println("survey output file ", survey_output_file)     

    grid_data = read_data_grid(grid_file_name)

    # change the filetype to be csv and read the route file
    route_file_name = string(replace(grid_file_name, ".grd" => ".csv"))

    route_data = CSV.read(route_file_name, DataFrame; delim=',', header=true)
    #println("route_data_names",names(route_data))
    rename!(route_data, [col => replace(col, " " => "_") for col in names(route_data)])
    println("replaced route data names ", names(route_data))
    HMD_output = fn_build_hmdif(grid_data, survey_ID, route_data)
    #println("survey name ", survey_name)

#print(typeof(HMD_output))

#println(HMD_output)



    open(survey_output_file, "w") do file
        for line in HMD_output
            #if length(line) > 3
            write(file, line)
        #end
        end
    end
end

main()