function find_rows_with_value(section_df::DataFrame, cvi_code::String)
    # remove the sectionID, Chainage and sectionNr columns as the string used for the cvi code can occur in 
    # those columns.
    #print("find_rows_with_value")
    #println(section_df)

    #section_df = section_df[:1:21]

    section_df = select(section_df, Not([:Network, :SECTION_LE, :Length]))

    #println(section_df)
     
    rows_with_value = findall(row -> any(x -> x == cvi_code, row), eachrow(select(section_df, Not(:Chainage))))

    #println(typeof((section_df[rows_with_value, :]))) #0
    #println("typeof ",typeof(rows_with_value))
    row_number = size(section_df[rows_with_value, :],1)
    #println(row_number)
    #filter(row -> any(x -> x == value, row), eachrow(df))
    #@where(df, findall(x -> x == value))
    #print("exit find_rows_with_value")
    return row_number
end