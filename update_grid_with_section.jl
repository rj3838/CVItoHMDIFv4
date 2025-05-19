function update_section!(df_a::DataFrame, df_b::DataFrame)
    rename!(df_a, :"Section ID" => :"Section_ID")
    transform!(df_a, :"Chainage" => x -> parse.(Float64, x) => :"ChainageNr")
    for i in 1:nrow(df_a)
        change_value = df_a.ChainageNr[i]
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