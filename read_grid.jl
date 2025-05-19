function read_data_grid()

    csv_file = "Zone1_Route1.grd"

    # Read the CSV file into a DataFrame
    #df = CSV.read(csv_file, DataFrame; delim=',', header=22,
    #                        silencewarnings=true,
    #                        ignorerepeated=true)

    #println(first(df, 5))
    function read_until_empty(filename)
    rows = []
    open(filename, "r") do io
        header = readline(io)
        push!(rows, header)
        for line in eachline(io)
            if isempty(strip(line))
                break
            end
            push!(rows, line)
        end
    end
    return CSV.read(IOBuffer(join(rows, "\n")), DataFrame; skipto=23, delim=',',
                        silencewarnings=true,
                        ignorerepeated=true)    
end

df = read_until_empty("Zone1_Route1.grd")
    
return df

end
