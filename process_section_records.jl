function process_section_records(section_frame, network, section_number)

    # the survey record format is
        
    # SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;\n"
    survey_records = String[]
    
    #network_ID = network
    section_label = section_frame.SectionID[1]
    section_normdir = "F"
    section_survdir = section_frame.Direction[1]
    section_master = ""
    section_length = string(section_frame.SECTION_LE[1])
    section_comment = ""
    section_sdate = ""
    section_edate = ""
    section_stime = ""
    section_etime = ""
    section_insp = "TRL"
    #println("network: ", network, " section_number: ", section_number,"section_label: ", section_label)
    # Create the survey record
    survey_record = "SECTION\\$(network),$(section_number),$(section_label),$(section_normdir),$(section_survdir),$(section_master),$(section_length),$(section_comment),$(section_sdate),$(section_edate),$(section_stime),$(section_etime),$(section_insp);"
    # Convert the survey record to a string
    #survey_string = join(survey_record,"\n")
    #println("Creating section record: ", survey_record)
    survey_string = survey_record * "\n"  # Append a newline character to the end of the record

    # Append the survey record to the section records
         
    push!(survey_records, survey_string)

    # so the observ and obval lines are processed for each section they need to be
    # processed in the context of the section they belong to.
    # This means that the section_frame should be used to create the observ and obval lines
    # for each section.

    # produce a grouped data frame broken into 20 metre subsections
    # this is done by grouping the section_frame by SectionID and then by StartCh (which changes every 20 metres)
    grouped_section = DataFrames.groupby(section_frame, [:SectionID, :StartCh]) 

    #println("Grouped section: ", grouped_section)
    observation_number::Int16 = 0
    last_obs_number::Int16 = 0
    #pass the grouped section to the process_observations function

    #for (frame_number,section_df) in enumerate(grouped_section)
    for section_df in grouped_section
        # which frame number is this ?
        #println("frame number :", frame_number)
        #println("Processing section_df: ", section_df)
        # process the observations and obvals for each section
        section_df = DataFrame(section_df)  # Ensure section_df is a DataFrame
        # pass the last observation number in so the obs number runs in order.
        observation_number = last_obs_number
        hmd_records, last_obs_number = process_observ_records(section_df, observation_number) # frame_number)
        #println("HMD Records: ", hmd_records)
        # append the records to the survey records
        append!(survey_records, hmd_records)
    end
    return survey_records
end