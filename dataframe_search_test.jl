using DataFrames

# Create DataFrame with multiple ranges of the number
data = Dict(
    "A" => [1, 7, 3, 4, 7, 7],
    "B" => [5, 6, 1, 8, 9, 9],
    "C" => [7, 10, 10, 11, 7, 7],
    "D" => [13, 13, 14, 15, 7, 7],
    "E" => [7, 10, 10, 11, 7, 7],
)
df = DataFrame(data)
println(df)

# Find positions of the specific number
# number_to_find = 7
# positions = findall(x -> x == number_to_find, df)
# Find positions of the specific number
number_to_find = 7
positions = []
for (i, row) in enumerate(eachrow(df))
    for (j, val) in enumerate(row)
        if val == number_to_find
            push!(positions, (i, j))
        end
    end
end

# Check for adjacent positions
function is_adjacent(pos1, pos2)
    return abs(pos1[1] - pos2[1]) <= 1 && abs(pos1[2] - pos2[2]) <= 1
end

# adjacent_positions = []
# for i in 1:length(positions)
#     for j in i+1:length(positions)
#         if is_adjacent(positions[i], positions[j])
#             push!(adjacent_positions, positions[i])
#             push!(adjacent_positions, positions[j])
#         end
#     end
# end

# # Remove duplicates
# adjacent_positions = unique(adjacent_positions)

# # Extract row and column indices
# rows = [pos[1] for pos in adjacent_positions]
# cols = [pos[2] for pos in adjacent_positions]

# # Determine the ranges
# row_ranges = [(minimum(rows), maximum(rows))]
# col_ranges = [(minimum(cols), maximum(cols))]

# # Print all occurrences and the ranges
# println("Occurrences of $number_to_find:")
# for pos in adjacent_positions
#     println("Row: $(pos[1]), Column: $(pos[2])")
# end
clusters = []
global visited = Set()
for pos in positions
    if pos in visited
        continue
    end
    cluster = [pos]
    local_visited = union(visited, Set(cluster))
    for other_pos in positions
        if other_pos in local_visited
            continue
        end
        if any(is_adjacent(pos, p) for p in cluster)
            push!(cluster, other_pos)
            local_visited = union(visited, Set(cluster))
        end
    end
    push!(clusters, cluster)
end
# sort the cluster contents
for  cluster_content in clusters
    sort!(cluster_content)
end
# Remove duplicate clusters
unique_clusters = unique(clusters)

# Extract the row and column indices for each cluster
row_ranges = [(minimum([pos[1] for pos in cluster]), maximum([pos[1] for pos in cluster])) for cluster in unique_clusters]
col_ranges = [(minimum([pos[2] for pos in cluster]), maximum([pos[2] for pos in cluster])) for cluster in unique_clusters]

# Print all unique clusters and their ranges
println("Clusters of $number_to_find:")
for (i, cluster) in enumerate(unique_clusters)
    println("Cluster $i:")
    for pos in cluster
        println("  Row: $(pos[1]), Column: $(pos[2])")
    end
    println("  Row range: $(row_ranges[i])")
    println("  Column range: $(col_ranges[i])")
end
# println("Row ranges: $row_ranges")
# println("Column ranges: $col_ranges")