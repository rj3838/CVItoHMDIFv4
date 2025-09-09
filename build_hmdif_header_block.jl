# function to build the HMD header block

function build_hmdif_header_block(survey_name::String)

    # Build the output HMDIF
    # header is standard
    HMDIF_out = String[] # empty list/array
    line1 = "HMSTART ukPMS 001 \" \" ; , \\\n"
    line2 = "TSTART;\n"
    line3 = "SURVEY\\TYPE,VERSION,NUMBER,NAME,SUBSECT,CWXSPUSED,OFFCWXSPUSED;\n"
    line4 = "SECTION\\NETWORK,NUMBER,LABEL,NORMDIR,SURVDIR,MASTER,LENGTH,COMMENT,SDATE,EDATE,STIME,ETIME,INSP;\n"
    line5 = "OBSERV\\NUMBER,DEFECT,VERSION,XSECT,SCHAIN,ECHAIN;\n"
    line6 = "OBVAL\\PARM,OPTION,VALUE,PERCENT;\n"
    line6a = "OBNOTE\\NOTE,COMMENT;\n"
    line7 = "TEND\\7;\n"
    line8 = "DSTART;\n"

    push!(HMDIF_out, line1,
                    line2,
                    line3,
                    line4,
                    line5,
                    line6,
                    line6a,
                    line7,
                    line8)

    #survey_record = "SURVEY\\CVI,235,5,$survey_name,,,;\n"
    #push!(HMDIF_out,survey_record)

    return HMDIF_out

end