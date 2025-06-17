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
    println("network: ", network, " section_number: ", section_number,"section_label: ", section_label)
    # Create the survey record
    survey_record = "SECTION\\$(network),$(section_number),$(section_label),$(section_normdir),$(section_survdir),$(section_master),$(section_length),$(section_comment),$(section_sdate),$(section_edate),$(section_stime),$(section_etime),$(section_insp);"
    # Convert the survey record to a string
    #survey_string = join(survey_record,"\n")
    #println("Creating section record: ", survey_record)
    survey_string = survey_record * "\n"  # Append a newline character to the end of the record

    # Append the survey record to the section records
         
    push!(survey_records, survey_string)

end