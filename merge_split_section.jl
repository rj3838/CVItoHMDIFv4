# Import the DataFrames package
using DataFrames

function merge_split_sections(survey_records_df::DataFrame, corrected_survey_records_df::DataFrame)

    dfA = survey_records_df
    dfB = corrected_survey_records_df
    # --- 1. Create Sample DataFrames ---
    # dfA: The primary DataFrame, all its rows should be in the final output.
        # dfA = DataFrame(
        #     colA = ["A", "B", "C", "D", "F"],
        #     colB = [1, 2, 3, 4, 6],
        #     value_A1 = ["alpha", "beta", "gamma", "delta", "epsilon"],
        #     value_A2 = [10, 20, 30, 40, 60],
        #     exclusive_A = ["only_A1", "only_A2", "only_A3", "only_A4", "only_A5"]
        # )

        # # dfB: The DataFrame used to overwrite values for matching rows.
        # dfB = DataFrame(
        #     colA = ["B", "C", "E"],
        #     colB = [2, 3, 5],
        #     value_A1 = ["B_new_alpha", "C_new_beta", "E_new_gamma"], # Same column name as in dfA, will be renamed during join
        #     value_B2 = [200, 300, 500],                             # New column from dfB
        #     exclusive_B = ["only_B1", "only_B2", "only_B3"]
        # )

    # println("--- Original dfA ---")
    # println(dfA)
    # println("\n--- Original dfB ---")
    # println(dfB)

    # dfA = CSV.read("survey_records.csv", DataFrame)
    # dfB = CSV.read("corrected_survey_records.csv", DataFrame) 

    dfB = select(dfB, Not([:OriginalRow])) # Remove the OriginalRow column if it exists

    # --- 2. Perform a leftjoin to combine data and identify matches ---
    # We use `leftjoin` to ensure all rows from dfA are kept.
    # `on = [:colA, :colB]` specifies the columns to join on.
    # `makeunique=true` handles cases where dfA and dfB have columns with the same name
    # (other than the join keys). It appends `_1` to dfB's duplicate column names.
    # `source=:_source` adds a temporary column `_source` indicating if a row came
    # from "left_only" (dfA only) or "both" (dfA and dfB).
    intermediate_df = leftjoin(dfA, dfB, on = [:SectionID, :Chainage], makeunique=true, source=:_source)

    println("\n--- Intermediate DataFrame after leftjoin ---")
    #println(intermediate_df)
    println("Note the `_source` column and potentially renamed columns from dfB (e.g., value_A1_1).")


    # --- 3. Identify rows that had a match in dfB ---
    # These are the rows where the original `colA` and `colB` values were present in both DataFrames.
    # The `_source` column will have "both" for such rows.
    matched_rows_mask = intermediate_df[!, :_source] .== "both"


    # --- 4. Conditionally overwrite columns from dfA with values from dfB ---
    # We need to explicitly identify which columns from dfA should be overwritten
    # by their counterparts from dfB.
    # This assumes a naming convention or a pre-defined list of columns to merge.
    # In this example, 'value_A1' from dfA should be overwritten by 'value_A1_1' from dfB (due to makeunique).
    # 'value_A2' from dfA will remain if no corresponding column in dfB, or be kept as is.
    # 'value_B2' is a new column from dfB that we want to keep where there was a match.

    # List columns in dfA that might be overwritten by a corresponding column in dfB.
    # (Excluding the join keys and columns that are only in dfA without a B counterpart).
    dfA_columns_to_potentially_overwrite = [:StartCh, :EndCh, :Length] # Add any other columns from dfA that should be overwritten

    # Iterate through these columns and perform the overwrite.
    # We also need to consider the renamed columns from dfB due to `makeunique=true`.
    for col_a_name in dfA_columns_to_potentially_overwrite
        # Construct the potential corresponding column name from dfB after makeunique
        # This logic assumes the default renaming by DataFrames.jl (appending _1)
        col_b_name = Symbol(String(col_a_name) * "_1") # e.g., :value_A1 becomes :value_A1_1

        # Check if the corresponding dfB column actually exists in the intermediate_df
        if hasproperty(intermediate_df, col_b_name)
            # For the rows that matched (`matched_rows_mask` is true),
            # replace dfA's value with dfB's value (which is in col_b_name).
            # For rows that didn't match (left_only), the value in col_a_name remains untouched.
            intermediate_df[matched_rows_mask, col_a_name] = intermediate_df[matched_rows_mask, col_b_name]
        end
    end

    # --- 5. Clean up the DataFrame ---
    # Remove the temporary `_source` column and the now redundant `_1` suffixed columns from dfB.

    # Collect names of columns from dfB that were added/renamed during the join.
    # This includes `exclusive_B` and `value_A1_1` (renamed from dfB's value_A1).
    # We keep `value_B2` as it's a new column from dfB that should be present in the final output.
    columns_to_remove = Symbol[]
    push!(columns_to_remove, :_source)

    # Find all columns in the intermediate_df that end with '_1' and add them to the removal list
    for col_name in names(intermediate_df)
        if endswith(col_name, "_1")
            push!(columns_to_remove, Symbol(col_name))
        end
    end

    # Add columns from dfB that were merged/renamed and are now redundant
    # This needs to be carefully managed based on your specific column names and merge strategy.
    # Here, `value_A1_1` is the renamed column from `dfB` that we used to overwrite `value_A1`.
    # `exclusive_B` is a new column from `dfB` that we want to keep in the final DataFrame,
    # so we don't add it to `columns_to_remove`.
    if hasproperty(intermediate_df, :value_A1_1)
        push!(columns_to_remove, :value_A1_1)
    end

    # Use `select!` to remove the specified columns in-place.
    final_df = select(intermediate_df, Not(columns_to_remove))

    println("\n--- Final Merged DataFrame ---")
    #println(final_df)
    # unique rows only and sort the final DataFrame by SectionID and Chainage for better readability
    # helps processing it too!
    final_df = unique(final_df)
    final_df = sort(final_df, [:SectionID, :Chainage])

    CSV.write("final_merged_data.csv", final_df, header=true)

    return final_df
end

