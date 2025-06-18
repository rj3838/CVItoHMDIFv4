function create_survey_name(grid_file_name)
    # open the grid_file_name in read mode
    grid_file = open(grid_file_name, "r")

    # Read the first line and get the original filename from item

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