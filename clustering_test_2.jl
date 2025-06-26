function find_value_clusters(
    df::DataFrame,
    column::Symbol,
    target_value;
    return_dataframe::Bool = false,
)
    # Find all row indices where the column equals the target value.
    indices = findall(==(target_value), df[!, column])

    # Handle the case where the target value is not found.
    if isempty(indices)
        return []
    end

    # Group consecutive indices into clusters.
    clusters = Vector{Vector{Int64}}()  # Explicitly type clusters
    current_cluster = [indices[1]]

    for i in 2:length(indices)
        if indices[i] == indices[i - 1] + 1
            push!(current_cluster, indices[i])
        else
            push!(clusters, current_cluster)
            current_cluster = [indices[i]]
        end
    end
    push!(clusters, current_cluster) # Add the last cluster.

    if return_dataframe
        # Return clusters as a vector of DataFrames.
        cluster_dfs = [df[cluster_indices, :] for cluster_indices in clusters]
        return cluster_dfs
    else
        # Return clusters as a vector of vectors of indices.
        return clusters
    end
end

function main()
    # Example DataFrame
    df = DataFrame(A = [1, 2, 2, 2, 5, 6, 7, 7, 2, 2, 2, 2, 9])
    target_value = 2
    column_name = :A

    # Find and print the clusters of indices.
    clusters_indices = find_value_clusters(df, column_name, target_value; return_dataframe=false)
    println("Clusters of $target_value (indices):")
    for cluster in clusters_indices
        println(cluster)
    end

    # Find and print the clusters as DataFrames.
    clusters_dataframes = find_value_clusters(df, column_name, target_value; return_dataframe=true)
    println("\nClusters of $target_value (DataFrames):")
    for cluster_df in clusters_dataframes
        println(cluster_df)
    end

    # Example with a DataFrame containing different data types, and missing values
    df2 = DataFrame(
    A = [1, 7, 3, 4, 7, 7],
    B = [5, 6, 1, 8, 9, 9],
    C = [7, 10, 10, 11, 7, 7],
    D = [13, 13, 14, 15, 7, 7],
    E = [7, 10, 10, 11, 7, 7])
    # df2 = DataFrame(A = [1, 2, 2, missing, 5, 2, 7, 7, 2, 2, missing, 2, 9],
    #                 B = ["a", "b", "b", "c", "d", "b", "e", "e", "b", "b", "f", "b", "g"],
    #                 C = [1.0, 2.0, 2.0, 3.0, 5.0, 2.0, 7.0, 7.0, 2.0, 2.0, 8.0, 2.0, 9.0])
    target_value2 = 7
    column_name2 = :A

    clusters_indices2 = find_value_clusters(df2, column_name2, target_value2; return_dataframe=false)
    println("\nClusters of $target_value2 in df2 (indices):")
    for cluster in clusters_indices2
        println(cluster)
    end

    clusters_dataframes2 = find_value_clusters(df2, column_name2, target_value2; return_dataframe=true)
    println("\nClusters of $target_value2 in df2 (DataFrames):")
    for cluster_df in clusters_dataframes2
        println(cluster_df)
    end
end

main()
