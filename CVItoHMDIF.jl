#This program is written Julia.
#
# The purpose is to read a Chartcrack grid from a CVI survey and produce a HMD for eventusl upload to a PMS

# Select file to open

using NativeFileDialog
using FilePathsBase
using CSV
using DataFrames
using DataFramesMeta

function fn_gdf_iterate(gdf_passed)

    [section_process(i) for i in gdf_passed]

end

# Function to find rows containing a specific value
"""
    find_rows_with_value(df::DataFrame, value::Any)

TBW
"""
function find_rows_with_value(df::DataFrame, value::Any)
    #search_value = String(value)
    filter(row -> any(x -> x == value, row), eachrow(df))
    #@where(df, findall(x -> x == value))
    return
end

function section_process(section_df)
    println("from section_process")
    section = section_df.SectionID[1]
    section_nr =section_df.sectionNr[1]
    start_chainage = first(section_df.Chainage)
    last_chainage = last(section_df.Chainage)
    length = last_chainage - start_chainage
    println("section ", section, " section number ", section_nr," start ", start_chainage, " last ", last_chainage, " section length ", length)

    #BNAS - code 19 Not assesed
    #cvi_code = "19"
    #bnas_rows = find_rows_with_value(section_df, 19)
    #println("BNAS", bnas_rows)


    #println(section_df)
    
end


function fn_hmd_cvi_data_records(grid_data)

    # drop rows with missing fields, this drops the dummy OSGR data at the end of the file.
    dropmissing!(grid_data)

    # rename the 'Section ID' by removing the spaces as it's easier to deal with.
    rename!(grid_data, Symbol("Section ID") => :SectionID)
    
    # convert the chainage to a float then
    # create a new column using flooring division on the Chaniage to produce a 'new' section number each 20m
    # then convert it to a string.
    transform!(grid_data, :Chainage => ByRow(x -> parse(Float64, x)) => :Chainage)
    @rtransform!(grid_data, :sectionNr = fld1(:Chainage, 20))
    @rtransform!(grid_data, :sectionNr = string(round(Int, :sectionNr)))

    # Section Id and sectionNr can now be used to create a grouped data frame.
    gdf_grid_data = groupby(grid_data, [:SectionID, :sectionNr])

    # now for each grouped DF create records for section + observ + obval 

    #println(gdf_grid_data) # just to check

    gdf_data_records = fn_gdf_iterate(gdf_grid_data)

    # don't forget to return the data record strings.
    #print(gdf_data_records)

    return 
end

function fn_build_hmdif(grid_data, survey_name)

# Build the output HMDIF
# header is standard
    HMDIF_out = [] # empty list/array
    line1 = "HMSTART ukPMS 001  ; , \\"
    line2 = "TSTART;"
    line3 = "SURVEY\\TYPE,VERSION,NUMBER,NAME,SUBSECT,CWXSPUSED,OFFCWXSPUSED;"
    line4 = "SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;"
    line5 = "OBSERV\\NUMBER,DEFECT,VERSION,XSECT,SCHAIN,ECHAIN;"
    line6 = "OBVAL\\PARM,OPTION,VALUE,PERCENT;"
    line7 = "TEND\\7;"
    line8 = "DSTART;"

    push!(HMDIF_out, line1,
                    line2,
                    line3,
                    line4,
                    line5,
                    line6,
                    line7,
                    line8)

    survey_record = "SURVEY\\CVI,235,5,$survey_name,,,;"
    push!(HMDIF_out,survey_record)
    #println(HMDIF_out)
    #println(typeof(HMDIF_out))
    #println(size(HMDIF_out))       
    #HMDIF_out = split(HMDIF_header, '\r')

# TODO build the data records

# building the data in a seperate function

data_out = fn_hmd_cvi_data_records(grid_data)

# TODO calculate the number of data records in the list(includes DSTART and DEND records)
# DSTART is always at 9

    HMDIF_count = size(HMDIF_out)[1]
    dend_count = Int(HMDIF_count) - 6
    #println(dend_count)
    #DEND_string = raw"DEND\\" + string(dend_value) + raw";"
    DEND_string = "DEND\\$dend_count;"
    push!(HMDIF_out, DEND_string)
    #println(HMDIF_out)
    # print("""DEND\\""", dend_value)

# HMEND is the length of HMDIF_out plus one.
    HMDIF_count = Int(size(HMDIF_out)[1]) + 1
    HMEND_string = "HMEND\\$HMDIF_count;"
    push!(HMDIF_out, HMEND_string)
    return HMDIF_out
end

# TODO uncomment the following two before full test
#grid_file_name = pick_file()
#println(grid_file_name)

# Read the first line and get the original filename from it

# Open the file in read mode
#file = open(grid_file_name, "r")
file = open("Test Grid 2.grd", "r")

# Read the first line and close it
first_line = readline(file)
close(file)

# Print the first line
println(first_line)

#Use the string after the word 'file' as the survey name

survey_name = split(first_line, r"^.+file ")[:2]

# print(survey_name)


# replace the spaces with an underscore and append HMD
survey_output_file = string(replace(survey_name, " " => "_") * ".HMD")

println("output file is ", survey_output_file)

#now go and get the full file skipping the first 22 rows as they are the explanation of the codes.
grid_file_name = "Test Grid 2.grd"

grid_data = CSV.read(grid_file_name, DataFrame; header=22,
                                                silencewarnings=true)

#grid_data

HMD_output = fn_build_hmdif(grid_data, survey_name) 

print(HMD_output)