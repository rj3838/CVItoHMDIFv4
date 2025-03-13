#This program is written Julia.
#
# The purpose is to read a Chartcrack grid from a CVI survey and produce a HMD for eventusl upload to a PMS

# Select file to open

using NativeFileDialog
using FilePathsBase
using CSV
using DataFrames

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

#grid_data = CSV.read(grid_file_name, 
#row_one = first(grid_data)

print(survey_output_file)

grid_data = CSV.read(grid_file_name, DataFrame; header=22)

grid_data

