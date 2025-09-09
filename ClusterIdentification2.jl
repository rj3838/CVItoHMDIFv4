# Cluster identification
#module ClusterIdentification

#export find_value_clusters, fn_cluster_ident

import DataFrames as df

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
    #println("names(input_df)", names(input_df))
    # remove the sectionNr or the clusters will incluce the sectionNr !
    #df.select!(input_df, Not([:SectionID, :Chainage, :Direction, :StartCh, :EndCh, :Length, :SECTION_LE, :Network]))

    #println("cluster cols: ", names(input_df))

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

