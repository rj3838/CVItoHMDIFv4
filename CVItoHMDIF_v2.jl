#This program is written Julia.
#
# The purpose is to read a Chartcrack grid from a CVI survey and produce a HMD for eventual upload to a PMS

using NativeFileDialog
using FilePathsBase
using CSV
using DataFrames
using DataFramesMeta
using Gtk

include("ClusterIdentification2.jl")
include("cvi_calculations.jl")
include("update_grid_with_section_2.jl")
##include("Section_length.jl")
include("read_grid.jl")
#include("fn_hmd_cvi_data_records.jl")
include("find_rows_with_value.jl")
include("create_survey_name.jl")
include("open_route_file.jl")
include("open_section_file.jl")
include("build_main_df.jl")
include("build_hmdif_header_block.jl")
include("process_combined_data.jl")
include("process_section_records.jl")
include("correct_split_sections.jl")
#include("merge_split_section.jl")
include("process_observ_records_v4.jl")
include("hmd_tail_records.jl")
include("fn_lateral_calc.jl")
include("process_buts_record.jl")
include("create_survey_record.jl")
include("fn_get_multiple_data_grd_filenames.jl")
include("fn_grid_processing.jl")
include("categorise_value_ternary.jl")

# function fn_gdf_iterate(gdf_passed)

#     println("calling section process")
#     [section_process(i) for i in gdf_passed]
# end

#start of main

function main()
    println("CVI to HMDIF")
    println("Select a CVI grid file to convert to HMDIF")

# Open the file in read mode

    grid_file_names = fn_get_multiple_data_csv_filenames("Select CVI grid files")

    # create the survey name and survey file name and read the grid

    #survey_output_file, survey_ID = create_survey_name(grid_file_name)

    #println("survey name ", survey_ID)
    #println("survey output file ", survey_output_file)

    section_file_name = "East Sussex Sections 2025.csv"

    # read the section file

    section_df = open_section_file(section_file_name)
    #println("grid_file_names ", grid_file_names)

    # process each grid file in turn
    foreach(grid_file_name -> println("Processing file: $grid_file_name"), grid_file_names)

    #foreach(fn_grid_processing, grid_file_names, Ref(section_df))
    # println("Starting foreach")
    for file_name in grid_file_names
        println("About to process: ", file_name)
        fn_grid_processing(file_name, section_df)
        println("Finished processing: ", file_name)
        println("---------------------------------------------------")
    end

    # but we need to clean up the data a bit more, the data where there is a diversion off onto a different section
    # which then returns to the original section.
    # the main chainage doesn't change as it is the distance into the survey grid but startC, endCh and length needs
    # to twidled a bit.

    #corrected_df = correct_diverted_sections(combined_df)

    #rename!(route_data, [col => replace(col, " " => "_") for col in names(route_data)])
#     println("replaced route data names ", names(route_data))
#     HMD_output = fn_build_hmdif(grid_data, survey_ID, route_data)
#     #println("survey name ", survey_na
    # # end of main
    #print("grid file names processed", grid_file_names)
end

Base.invokelatest(main)
