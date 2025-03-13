#This program is written Julia.
#
# The purpose is to read a Chartcrack grid from a CVI survey and produce a HMD for eventusl upload to a PMS

# Select file to open

using NativeFileDialog
using FilePathsBase
using CSV
using DataFrames

function fn_build_hmdif()

# Build the output HMDIF
# header is standard
    HMDIF_header = """HMSTART ukPMS 001 " " ; , \\
                    TSTART;
                    SURVEY\\TYPE,VERSION,NUMBER,NAME,SUBSECT,CWXSPUSED,OFFCWXSPUSED;
                    SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;
                    OBSERV\\NUMBER,DEFECT,VERSION,XSECT,SCHAIN,ECHAIN;
                    OBVAL\\PARM,OPTION,VALUE,PERCENT;
                    OBNOTE\\NOTE,COMMENT;
                    TEND\\7;
                    DSTART;"""
    HMDIF_out = HMDIF_header
# TODO calculate the number of data records (includes DSTART and DEND records)

# TODO calculate the number of total HMD records (includes HMSTART and HMEND records)
    return HMDIF_out
end

grid_file_name = pick_file()

println(grid_file_name)

# Read the first line and get the original filename from it

# Open the file in read mode
file = open(grid_file_name, "r")

# Read the first line and close it
first_line = readline(file)
close(file)

# Print the first line
println(first_line)

#Use the string after the word file as the survey name

survey_name = split(first_line, r"^.+file ")[:2]

# print(survey_name)


# replace the spaces with an underscore and append HMD
survey_output_file = string(replace(survey_name, " " => "_") * ".HMD")

print(survey_output_file)

#now go and get the full file skipping the first 22 rows as they are the explanation of the codes.

grid_data = CSV.read(grid_file_name, DataFrame; header=22)

grid_data

HMD_output = fn_build_hmdif() 

print(HMD_output)

