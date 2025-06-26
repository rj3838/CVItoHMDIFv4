# opens the route file

using DataFrames, CSV

function open_section_file(section_file::String)
    if !isfile(section_file)
        error("Route file does not exist: $section_file")
    end

    try
        section_data = CSV.read(section_file, DataFrame, 
            delim=',', 
            header=true, 
            missingstring="",
            #stringtype=String,
            normalizenames=true)
            #dateparse=true,
            #allowmissing=true)
            #skipto=1)  # Skip the first line if it contains metadata or comments
        println(section_data[1,:])
        return section_data
    catch e
        error("Failed to read route file: $(e)")
    end
    # current_col_name = names(section_data)[13]
    # new_col_name = :Network
    # rename!(section_data, current_col_name => new_col_name)
    # println(section_data[1,:])
end