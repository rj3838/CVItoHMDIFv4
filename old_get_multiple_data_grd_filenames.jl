using Gtk

function fn_get_multiple_data_grd_filenames(window_heading)
    # Create the GtkFileChooserDialog
    dialog = GtkFileChooserDialog(
        window_heading,
        nothing, 
        Gtk.FileChooserAction.OPEN,
        (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
         Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT)
    )

    # Create a file filter
    grd_filter = GtkFileFilter()
    
    # Corrected syntax: set the `name` field directly
    grd_filter.name = "Grid Files"
    
    # Corrected syntax: `add_pattern` is a function
    Gtk.add_pattern(grd_filter, "*.grd")

    # Add the filter to the dialog
    Gtk.add_filter(dialog, grd_filter)

    # Enable multiple file selection
    Gtk.set_select_multiple(dialog, true)

    # Run the dialog and get the response
    response = run(dialog)

    # Check the user's response
    if response == Gtk.ResponseType.ACCEPT
        filenames = Gtk.get_filenames(dialog)
        destroy(dialog)
        return filenames
    else
        destroy(dialog)
        return nothing
    end
end