# opens the route file

using DataFrames, CSV

function open_route_file(route_file::String)
    if !isfile(route_file)
        error("Route file does not exist: $route_file")
    end

    try
        route_data = CSV.read(route_file, DataFrame, 
            delim=',', 
            header=true, 
            missingstring="",
            #stringtype=String,
            normalizenames=true,
            types=Dict(:Direction => String))
            #dateparse=true,
            #allowmissing=true)
            #skipto=1)  # Skip the first line if it contains metadata or comments
        
        return route_data
    catch e
        error("Failed to read route file: $(e)")
    end
    
end