#using IterTools

function hmd_tail_records(hmd_records)

    #calculate and add the DEND and HMEND records for the HMDIF file
    #println("hmd_records type ",typeof(hmd_records))

    # remove empty strings (lines) before the length calculation
    filter!(!isempty, hmd_records)

    hmdif_count = size(hmd_records)[1]
    #println("process test ", lastindex(hmd_records))

    #println("hmdif_count = ", hmdif_count)

    # hmd_records = vcat(hmd_records)
    # hmd_single_vector = Iterators.flatten(hmd_records)

    # hmd_collected = collect(hmd_single_vector)

    # println("process test ", lastindex(hmd_collected))

    # filter!(!isempty, hmd_collected)

    hmdif_count = hmdif_count + 2 # we are adding 2 lines

    data_count = hmdif_count - 9 # there are 8 lines in the header after DEND we don't count

    hmd_tail = Vector{String}()
    
    push!(hmd_tail, "DEND $data_count;\n")

    push!(hmd_tail, "HMEND $hmdif_count;")

    #println(hmd_tail)
    
    return hmd_tail

end