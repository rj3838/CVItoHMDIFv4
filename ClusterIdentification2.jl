# Cluster identification
#module ClusterIdentification

#export find_value_clusters, fn_cluster_ident

using DataFrames


# Finds clusters of a target value within a DataFrame, allowing for clusters that span multiple rows and columns, based on connectivity.

# Args:
#     df::DataFrame: The input DataFrame.
#     target_value: The value to find clusters of.
#     connectivity::Symbol:  The type of connectivity to consider:
#         - :rook:  Elements are considered connected if they share an edge.
#         - :queen (default): Elements are considered connected if they share an edge or a corner.

# Returns:
#     Vector{Vector{CartesianIndex{2}}}: A vector of clusters, where each cluster is a
#     vector of CartesianIndex{2} objects.  Each CartesianIndex{2} represents
#     the (row, column) coordinates of a cell in the DataFrame that
#     contains the target value. Returns [] if target_value is not found.


function find_value_clusters(
    input_df::DataFrame,
    target_value:: Any;
    connectivity::Symbol = :queen,)

    #println("find_value_clusters target value ", target_value)

    # remove the sectionNr or the clusters will incluce the sectionNr !
    select!(input_df, Not(:SectionID))

    # Check for valid connectivity type.
    # if connectivity != :rook && connectivity != :queen
    #     throw(ArgumentError("connectivity must be either :rook or :queen"))
    # end

    # Find all occurrences of the target value and store their coordinates.
    coordinates = CartesianIndex{2}[]
    for col_index in 1:ncol(input_df)
        col_name = names(input_df)[col_index]  # Get column name
        for (row_index, value) in enumerate(input_df[!, col_name])
            compare_value_string = string(value)
            compare_target_value_string = string(target_value)
            if compare_value_string == compare_target_value_string
                push!(coordinates, CartesianIndex(row_index, col_index))
            end
        end
    end
    #println("leaving find_value_clusters ", coordinates)
    # Handle the case where the target value is not found.
    if isempty(coordinates)
        return []
    end


    # Function to get neighbors of a given coordinate.
    function get_neighbors(coord::CartesianIndex{2}, connectivity::Symbol, max_row::Int, max_col::Int)
        neighbors = CartesianIndex{2}[]
        r, c = coord.I

        if connectivity == :rook
            # Check neighbors directly above, below, left, and right.
            candidates = [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)]
        elseif connectivity == :queen
            # Check all surrounding neighbors (including diagonals).
            candidates = [
                (r - 1, c - 1),
                (r - 1, c),
                (r - 1, c + 1),
                (r, c - 1),
                (r, c + 1),
                (r + 1, c - 1),
                (r + 1, c),
                (r + 1, c + 1),
            ]
        end
        
        for (nr, nc) in candidates
            if 1 <= nr <= max_row && 1 <= nc <= max_col
                push!(neighbors, CartesianIndex(nr, nc))
            end
        end
        return neighbors
    end

    # Perform a breadth-first search to find clusters.
    max_row = size(input_df, 1)
    max_col = size(input_df, 2)
    clusters = Vector{Vector{CartesianIndex{2}}}()
    visited = Set{CartesianIndex{2}}()

    for start_coord in coordinates
        if start_coord in visited
            continue  # Skip if already part of a cluster.
        end

        cluster = [start_coord]
        push!(visited, start_coord)
        queue = [start_coord]

        while !isempty(queue)
            coord = popfirst!(queue)
            neighbors = get_neighbors(coord, connectivity, max_row, max_col)
            for neighbor in neighbors
                if neighbor in coordinates && !(neighbor in visited)
                    push!(visited, neighbor)
                    push!(cluster, neighbor)
                    push!(queue, neighbor)
                end
            end
        end
        push!(clusters, cluster)
    end
    #println("clusters ",clusters)
    return clusters
end

#function fn_cluster_ident(input_df::DataFrame, target_value::Int8)

    #println("fn_cluster_ident")
    # Example DataFrame
    # df = DataFrame(
    #     A = [1, 7, 3, 4, 7, 7],
    #     B = [5, 6, 1, 8, 9, 9],
    #     C = [7, 10, 10, 11, 7, 7],
    #     D = [13, 13, 14, 15, 7, 7],
    #     E = [7, 10, 10, 11, 7, 7])
    # target_value = 7

    # Find and print clusters with rook connectivity.
    # clusters_rook = find_value_clusters(df, target_value, connectivity=:rook)
    # println("Clusters of $target_value (rook connectivity):")
    # for cluster in clusters_rook
    #     println("Cluster:")
    #     for coord in cluster
    #         println(coord)
    #     end
    # end
    # function q(old_a, current_a, df_row)
    #     if current_a != old_a
    #         println("Value of 'a' changed from $old_a to $current_a at row:")
    #         println(df_row)
    #         # Add your processing logic for function q here
    #     end
    #     return current_a
    # end
    
    # function k(group::SubDataFrame)
    #     println("Processing group of $(size(group, 1)) rows for column 'b' starting with:")
    #     println(group[1,:])
    #     # Add your processing logic for function k here
    #     return nothing
    # end
    
    # println("Processing function q for changes in column 'a':")
    # old_a_value = nothing
    # for i in 1:nrow(input_df)
    #     old_a_value = q(old_a_value, input_df.a[i],imput_df[i,:])
    # end
    
    # println("\nProcessing function k for groups of 20 in column 'b':")
    # for i in 1:20:nrow(input_df)
    #     end_index = min(i + 19, nrow(input_df))
    #     group_b = @view input_df[i:end_index, :]
    #     k(group_b)
    # end

    # # Find and print clusters with queen connectivity.
    # clusters_queen = find_value_clusters(input_df, target_value, connectivity=:queen)
    # println("\nClusters of $target_value (queen connectivity):")
    # for cluster in clusters_queen
    #     println("Cluster:")
    #     for coord in cluster
    #         println(coord)
    #     end
    # end
#end #function end

#end #module end