================================================================================
BEAM SECTION TOOL - Compute cross-section properties from UNV meshes
================================================================================

Authors: Bruno Zilli & DeepSeek
Licence: MIT


PROJECT STRUCTURE
================================================================================

beam_section_tool/
│
├── src/                              # Fortran source files
│   ├── compute_section_properties.f  # Area, I_y, I_z calculation
│   ├── read_section_mesh_unv.f       # UNV file reader
│   ├── section_database.f            # Multi-section database
│   └── mesh_checker.f                # Mesh validation and correction
│
├── tests/                            # Test programmes
│   ├── test_section.f                # Basic test
│   ├── test_unv_reader.f             # UNV reader test
│   └── test_multi_section.f          # Multi-section database test
│
├── examples/meshes/                  # Example meshes
│   ├── rect_10x20.unv                # Rectangle 10x20 mm
│   ├── circle_dia10.unv              # Circle diameter 10 mm
│   └── HEB200_mm.unv                 # HEB200 from Salome
│
├── Makefile                          # Build system
├── README.txt                        # This file
└── LICENSE                           # MIT licence


STEP-BY-STEP COMPILATION
================================================================================

1. Open a terminal in the project directory:
    cd ~/Documenti/beam_section_tool

2. Clean any previous build (optional but recommended):
    make clean

   Expected output:
    rm -f *.o *.mod test_section test_unv_reader test_multi_section

3. Compile all modules:
    make

   Expected output:
    gfortran -Wall -O2 -c src/compute_section_properties.f -o compute_section_properties.o
    gfortran -Wall -O2 -c tests/test_section.f -o test_section.o
    gfortran -Wall -O2 -o test_section test_section.o compute_section_properties.o
    gfortran -Wall -O2 -c src/read_section_mesh_unv.f -o read_section_mesh_unv.o
    gfortran -Wall -O2 -c tests/test_unv_reader.f -o test_unv_reader.o
    gfortran -Wall -O2 -o test_unv_reader test_unv_reader.o read_section_mesh_unv.o
    gfortran -Wall -O2 -c src/section_database.f -o section_database.o
    gfortran -Wall -O2 -c tests/test_multi_section.f -o test_multi_section.o
    gfortran -Wall -O2 -o test_multi_section test_multi_section.o section_database.o
             read_section_mesh_unv.o compute_section_properties.o mesh_checker.o

4. Verify the executables were created:
    ls -la test_*

   Expected output:
    -rwxr-xr-x 1 user user 27000 test_multi_section
    -rwxr-xr-x 1 user user 17000 test_section
    -rwxr-xr-x 1 user user 22000 test_unv_reader

5. Run the multi-section test:
    ./test_multi_section


MANUAL COMPILATION (without Makefile)
================================================================================

If you prefer to compile manually:

1. Compile each module:
    gfortran -c src/compute_section_properties.f -o compute_section_properties.o
    gfortran -c src/read_section_mesh_unv.f -o read_section_mesh_unv.o
    gfortran -c src/section_database.f -o section_database.o
    gfortran -c src/mesh_checker.f -o mesh_checker.o

2. Compile the test programme:
    gfortran -c tests/test_multi_section.f -o test_multi_section.o

3. Link the executable:
    gfortran -o test_multi_section test_multi_section.o \
             section_database.o compute_section_properties.o \
             read_section_mesh_unv.o mesh_checker.o

4. Run:
    ./test_multi_section


USAGE
================================================================================

Quick test (all sections):
    ./test_multi_section

Test single section:
    ./test_section

Test UNV reader only:
    ./test_unv_reader


SECTIONS LIST FILE (sections_list.txt)
================================================================================

The file `sections_list.txt` defines which sections to load.
Format: ID Name filename.unv

Example:
    # Section list for multi-section analysis
    # Format: ID Name filename.unv
    1  IPE200      rect_10x20.unv
    2  Circle      circle_dia10.unv
    3  HEB200      HEB200_mm.unv
    4  MySection   my_mesh.unv

Lines starting with # are ignored.
The same UNV file is loaded only once even if referenced multiple times.


EXAMPLE OUTPUT
================================================================================

==========================================
  DETAILED SECTION PROPERTIES
==========================================

Section: HEB200
---------
File:        HEB200_mm.unv
Area (mm²):  7375.80
Area (cm²):  73.76
I_y (mm⁴):   54397296.37
I_y (cm⁴):   5439.73
I_z (mm⁴):   18919042.73
I_z (cm⁴):   1891.91


CONVENTIONS
================================================================================

Symbol   Meaning                          Axis
-------------------------------------------------------------------------------
I_y      Strong axis (vertical bending)   Horizontal
I_z      Weak axis (horizontal bending)   Vertical


SUPPORTED UNV FORMAT (Salome/ASTER)
================================================================================

  2411
         1         1         1        11
  -68.33306   4.16665   0.00000
         2         1         1        11
  -85.83299  21.66658   0.00000
...
  2412
     1    41     1     0
     1     2     3
     2    41     1     0
     1     3     4
...


MESH CHECKER
================================================================================

The tool automatically:
- Checks triangle orientation
- Flips inverted triangles
- Detects degenerate triangles (area too small)
- Reports total area after correction

Example output:
    MESH CHECKER: flipped 0 triangles
    MESH CHECKER: skipped 0 degenerate triangles
    MESH CHECKER: total area = 7375.80


NOTES
================================================================================

- Coordinates must be in mm for correct output in mm⁴
- Mesh checker automatically fixes triangle orientation
- Degenerate triangles are reported and skipped
- For HEB200, I_y error is ~4% (mesh from Salome)
- For I_z error is ~27% (needs finer mesh)


TROUBLESHOOTING
================================================================================

Problem: "No triangles found in file"
Solution: Check that the UNV file contains section 2412 with type 41 triangles

Problem: Negative area
Solution: Mesh checker will flip triangles automatically

Problem: Segmentation fault
Solution: Increase max_nodes and max_triangles parameters in source code

Problem: "make: command not found"
Solution: Install build-essential (Ubuntu/Debian) or Xcode (MacOS):
    sudo apt install build-essential

Problem: "gfortran: command not found"
Solution: Install gfortran:
    sudo apt install gfortran


ACKNOWLEDGEMENTS
================================================================================

- Salome Platform for mesh generation
- Code_Aster for reference UNV format

================================================================================
