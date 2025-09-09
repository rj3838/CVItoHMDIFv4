using Dates

function process_section_records(section_frame, network, section_number, survey_string)
    println("starting process_section_records for section: ", section_frame.SectionID[1])
    # extract the date and start time from the survey_ID
    survey_date = Dates.format(Date(split(survey_string, "_")[1], "yyyy-mm-dd"), "ddmmyyyy")

    time_part_string = split(survey_string, "_")[2]
    time_object = Time(time_part_string, "HHMM")
    survey_time = Dates.format(time_object, "HH:MM")
    survey_end = Dates.format(time_object + Minute(5), "HH:MM")

    # the survey record format is
        
    # SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;\n"
    survey_records = String[]
    #println("section FRAME ", section_frame[1,:])
    
    #network_ID = network
    section_label = section_frame.SectionID[1]
    section_normdir = "F"
    section_survdir = section_frame.Direction[1]
    section_master = "M"
    section_length = string(section_frame.SECTION_LE[1])
    section_comment = ""
    section_sdate = survey_date
    section_edate = survey_date
    section_stime = survey_time
    section_etime = survey_end
    section_insp = "TRL"
    #println("network: ", network, " section_number: ", section_number,"section_label: ", section_label)
    # Create the survey record
    survey_record = "SECTION\\$(network),$(section_number),$(section_label),$(section_normdir),$(section_survdir),$(section_master),$(section_length),$(section_comment),$(section_sdate),$(section_edate),$(section_stime),$(section_etime),$(section_insp);"
    # Convert the survey record to a string
    #survey_string = join(survey_record,"\n")
    #println("Creating section record: ", survey_record)
    survey_string = survey_record * "\n"  # Append a newline character to the end of the record

    # Append the survey record to the section records
    #println("section push")     
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
    println("ending process_section_records for section: ", section_frame.SectionID[1])
    return survey_records
end