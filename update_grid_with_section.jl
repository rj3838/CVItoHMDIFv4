function update_section!(df_a::DataFrame, df_b::DataFrame)
    # df_a is the grid
    # df_b is the route

    # convert all the chainagee values to float.
    df_a.Chainage = parse.(Float64, df_a.Chainage)
    #df_b.GRD_Start_Ch = parse.(Float64, df_b.GRD_Start_Ch)
    #df_b.GRD_End_Ch = parse.(Float64, df_b.GRD_End_Ch)
    rename!(df_a, :"Section ID" => :"Section_ID")
    #transform!(df_a, :"Chainage" => x -> parse.(Float64, x) => :"ChainageNr")
    for i in 1:nrow(df_a)
        change_value = df_a.Chainage[i]
        for j in 1:nrow(df_b)
            if df_b.GRD_Start_Ch[j] <= change_value <= df_b.GRD_End_Ch[j]
                df_a.Section_ID[i] = df_b.Section[j]
                break # Once a match is found, no need to check other rows in df_b
            end
        end
    end
    return df_a
end

# Example usage