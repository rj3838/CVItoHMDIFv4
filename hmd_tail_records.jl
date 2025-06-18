function hmd_tail_records(hmd_records)
    #calculate and add the DEND and HMEND records for the HMDIF file
    println("hmd_records type ",typeof(hmd_records))

    # remove empty strings (lines) before the length calculation
    #filter!(!isempty, hmd_records)

    hmdif_count = length(hmd_records)

    data_count = hmdif_count - 9 # there are 9 lines in the header

    hmd_tail = Vector{String}()
    
    push!(hmd_tail, "DEND $data_count;\n")

    push!(hmd_tail, "HMEND $hmdif_count;\n")

    println(hmd_tail)
    
    return hmd_tail

end