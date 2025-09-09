function fn_get_multiple_data_csv_filenames(window_heading)

    # ask for the reference file names
        ref_data_filenames = open_dialog_native(window_heading, GtkNullContainer(), String[], select_multiple=true)
    
        # types_dict = Dict(1 => String,
        #             2 => String,
        #             3 => String,
        #             4 => String,
        #             5 => String,
        #             6 => String,
        #             101 => Float64)
        # return the list of files selected
        return ref_data_filenames
    
    end