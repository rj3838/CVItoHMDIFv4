#This program is written Julia.
#
# The purpose is to read a Chartcrack grid from a CVI survey and produce a HMD for eventusl upload to a PMS

# Select file to open

using NativeFileDialog
using FilePathsBase
using CSV
using DataFrames
using DataFramesMeta

function fn_hmd_cvi_data_records(grid_data)

    #using DataFrames
    # drop rows with missing fields, this drop the dummy data at the end of the file.
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

    println(gdf_grid_data)
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

print(survey_output_file)

#now go and get the full file skipping the first 22 rows as they are the explanation of the codes.
grid_file_name = "Test Grid 2.grd"

grid_data = CSV.read(grid_file_name, DataFrame; header=22,
                                                silencewarnings=true)

#grid_data

HMD_output = fn_build_hmdif(grid_data, survey_name) 

print(HMD_output)