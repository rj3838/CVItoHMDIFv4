using DataFrames
using CSV

# test_df = CSV.read("Zone1_Route1.grd", DataFrame; delim=',', header=22, ignorerepeated=true,
#     silencewarnings=true)

    # Function to read CSV until a physically blank line is encountered
function read_csv_until_blank_line(filepath::String)
    lines_to_parse = String[]
    found_blank = false

    open(filepath, "r") do io
        for line in eachline(io)
            # Check if the line is effectively blank (only whitespace or truly empty)
            if strip(line) == ""
                found_blank = true
                break # Stop reading further lines
            end
            push!(lines_to_parse, line)
        end
    end

    if !found_blank
        println("Note: No physically blank line found in the file. Reading entire content.")
    end

    # Join the collected lines back into a single string and parse with CSV.read
    return CSV.read(IOBuffer(join(lines_to_parse, "\n")), DataFrame)
end

filepath = "Zone1_Route1.grd"

# Read the file
df_truncated = read_csv_until_blank_line("Zone1_Route1.grd")

CSV.write("truncated.csv", df_truncated, delim=',', header=true)