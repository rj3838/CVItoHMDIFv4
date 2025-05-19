function main()

  

    include("update_grid_with_section.jl")

    include("Section_length.jl")

    include("read_grid.jl")

    route_df = route_csv_to_df_processing()
    grid_df = read_data_grid()
    print(grid_df)

    merged_df = update_section!(grid_df, route_df)
    println("Merged DataFrame:")
    #println(merged_df)

end

using CSV
using DataFrames

include("update_grid_with_section.jl")

include("Section_length.jl")

include("read_grid.jl")

main()