using DataFrames
using Clustering
using NearestNeighbors

# Create DataFrame with multiple ranges of the number
data = Dict(
    "A" => [1, 7, 3, 4, 7, 7],
    "B" => [5, 6, 1, 8, 9, 9],
    "C" => [7, 10, 10, 11, 7, 7],
    "D" => [13, 13, 14, 15, 7, 7],
    "E" => [7, 10, 10, 11, 7, 7],
)

df = DataFrame(data)

dm= Matrix(df)

println(typeof(dm))

println(dm)

clusters = dbscan(dm,1, min_neighbors=1,
                    min_cluster_size=2)

