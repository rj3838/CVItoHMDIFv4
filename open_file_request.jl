# open file request

# Import the NativeFileDialog package
import NativeFileDialog as NFD

"""
    select_file_dialog()

Opens an operating system file selection window, allowing the user to choose a file.
Returns a tuple `(filename, filepath)` as text strings if a file is selected.
Returns `(nothing, nothing)` if the dialog is cancelled or no file is selected.

# Examples
```julia
filename, filepath = select_file_dialog()
if filename !== nothing
    println("Selected Filename: ", filename)
    println("Selected Filepath: ", filepath)
else
    println("File selection cancelled.")
end
```
"""
function select_file_dialog()
    # Open a single file selection dialog.
    # NFD.pick_file() returns a string representing the selected file path,
    # or an empty string if the dialog is cancelled.
    selected_filepath = NFD.pick_file()

    if isempty(selected_filepath)
        # If the string is empty, the user cancelled the dialog
        return nothing, nothing
    else
        # Extract the filename from the full path
        # basename() is a standard Julia function for this purpose
        filename = basename(selected_filepath)
        return filename, selected_filepath
    end
end

# --- Example Usage ---
# You can uncomment the following lines to test the function.
# When you run this code, a file selection window will pop up.

filename, filepath = select_file_dialog()

if filename !== nothing
    println("\n--- File Selected ---")
    println("Filename: ", filename)
    println("Full Filepath: ", filepath)
else
    println("\n--- File selection cancelled ---")
end