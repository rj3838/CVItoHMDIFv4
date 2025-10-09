function create_survey_record(survey_ID)
    
    survey_type = "CVI"
    survey_version = "235"
    survey_number = "5"
    survey_name = survey_ID
    survey_subsect = ""
    cwxsp_used = ""
    off_cwxsp_used = ""

        # Create the survey record
    survey_record = "SURVEY\\" * survey_type *
                            "," *   survey_version *
                            "," * survey_number *
                            "," * survey_name *
                            "," * survey_subsect *
                            "," * cwxsp_used *
                            "," * off_cwxsp_used *
                            ";\n"
    println("record type: ", typeof(survey_record))
    return survey_record
end