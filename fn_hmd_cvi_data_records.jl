
using DataFrames
using DataFramesMeta

function fn_hmd_cvi_data_records(grid_data)


    #this function needs the grid data to be modified before with the route information beforehand
    # in this way the grid data will only contain the relevant data for the survey

    # drop rows with missing fields, this drops the dummy OSGR data at the end of the file.
    dropmissing!(grid_data)
    
    # convert the chainage to a float then
    # create a new column using flooring division on the Chaniage to produce a 'new' section number each 20m
    # then convert it to a string.
    #transform!(grid_data, :Chainage => ByRow(x -> parse(Float64, x)) => :Chainage)
    @rtransform!(grid_data, :sectionNr = fld(:Chainage, 20))
    @rtransform!(grid_data, :sectionNr = string(round(Int, :sectionNr)))

    # Section Id and sectionNr can now be used to create a grouped data frame.

    gdf_grid_data = groupby(grid_data, [:SectionID, :StartCh])

    # now for each grouped DF create records for section + observ + obval 

    #println(gdf_grid_data) # just to check

    gdf_data_records = fn_gdf_iterate(gdf_grid_data)

    # don't forget to return the data record strings.
    #print(gdf_data_records)

    return gdf_data_records
end