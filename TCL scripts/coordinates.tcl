# Tcl sctipt to get the coordinates of the atoms selected 
# By Gabriel de Araújo Masanti 2024

# Make the selection of the two extremal oxygens awith index 2 and 48
set sel [atomselect top "index 2 48"]

# Create a variable to save the coordinates of the selection 
set coords [$sel get {x y z}]

# Print the coordinates
puts $coords

