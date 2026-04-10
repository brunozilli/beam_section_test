
markdown
# BEAM SECTION PROPERTIES TOOL
## A Fortran Library for Cross-Section Analysis
### Designed for CalculiX FEA Integration

**MIT License**

Copyright (c) 2024 Bruno Zilli & DeepSeek

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## TABLE OF CONTENTS

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [File Descriptions](#file-descriptions)
4. [Detailed Fortran Implementation](#detailed-fortran-implementation)
5. [Compilation and Testing](#compilation-and-testing)
6. [Usage Examples](#usage-examples)
7. [Test Results](#test-results)
8. [Future Developments](#future-developments)

---

## PROJECT OVERVIEW

This project provides a collection of Fortran routines for computing geometric properties of arbitrary cross-sections from 2D triangular meshes. The tool is specifically designed for integration with the **CalculiX** finite element solver to enable general beam elements with arbitrary cross-sectional shapes.

### Key Features

| Feature | Description |
|---------|-------------|
| **UNV File Reader** | Reads I-DEAS Universal File format (.unv) for 2D meshes |
| **Geometric Properties** | Computes area, centroid, moments of inertia, product of inertia |
| **Multi-Section Database** | Manages multiple cross-sections with unique identifiers |
| **Modular Architecture** | Easily extensible for torsion and shear centre calculations |
| **Test Suite** | Comprehensive tests for rectangles, circles and HEB sections |

### Theoretical Background

For a cross-section discretised into triangular finite elements, the geometric properties are computed using the following formulations:

- **Area**: `A = Σ A_tri`
- **Centroid**: `y_c = (Σ y_bar·A_tri) / A`, `z_c = (Σ z_bar·A_tri) / A`
- **Moment of Inertia (I_y)**: `I_y = Σ I_y_tri - A·z_c²`
- **Moment of Inertia (I_z)**: `I_z = Σ I_z_tri - A·y_c²`
- **Product of Inertia (I_yz)**: `I_yz = Σ I_yz_tri - A·y_c·z_c`

For each triangular element, the local contributions are:
Area_tri = ½·|(y₂-y₁)(z₃-z₁) - (y₃-y₁)(z₂-z₁)|
y_bar = (y₁ + y₂ + y₃)/3
z_bar = (z₁ + z₂ + z₃)/3
I_y_tri = (Area_tri/12)·(z₁² + z₂² + z₃² + 9·z_bar²)
I_z_tri = (Area_tri/12)·(y₁² + y₂² + y₃² + 9·y_bar²)
I_yz_tri = (Area_tri/12)·(y₁z₁ + y₂z₂ + y₃z₃ + 9·y_bar·z_bar)

text

---

## ARCHITECTURE

The software follows a modular, layered architecture:
┌─────────────────────────────────────────────────────────────────┐
│ INPUT: UNV Mesh Files │
│ (rect_10x20.unv, circle_dia10.unv, etc.) │
└─────────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────┐
│ read_section_mesh_unv.f │
│ Parses UNV format, extracts nodes and triangles │
└─────────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────┐
│ compute_section_properties.f │
│ Calculates A, y_c, z_c, I_y, I_z, I_yz │
└─────────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────┐
│ section_database.f │
│ Stores properties in memory with unique IDs │
│ Prevents duplicate loading of same mesh file │
└─────────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────┐
│ OUTPUT: Section Properties │
│ Ready for CalculiX BEAMGEN element │
└─────────────────────────────────────────────────────────────────┘

text

---

## FILE DESCRIPTIONS

### Core Source Files (`src/`)

| File | Purpose | Key Subroutines |
|------|---------|-----------------|
| `compute_section_properties.f` | Computes geometric properties from mesh data | `compute_section_properties()` |
| `read_section_mesh_unv.f` | Reads UNV format mesh files | `read_section_mesh_unv()` |
| `section_database.f` | Manages multiple cross-sections | `init_section_database()`, `add_section()`, `get_section_props()`, `list_all_sections()` |

### Test Files (`tests/`)

| File | Purpose |
|------|---------|
| `test_section.f` | Tests basic geometric properties on a rectangle |
| `test_unv_reader.f` | Tests UNV file reading functionality |
| `test_multi_section.f` | Tests multi-section database management |
| `test_circle.f` | Tests circular section properties |
| `test_all_meshes.f` | Loads and displays all mesh files |

### Example Mesh Files (`examples/`)

| File | Description | Dimensions |
|------|-------------|------------|
| `rect_10x20.unv` | Rectangle | 10 × 20 units |
| `circle_dia10.unv` | Circle | Diameter = 10 units |
| `l_section.unv` | L-angle section | Asymmetric test case |
| `heb240.unv` | HEB240 steel section | Simplified mesh |

---

## DETAILED FORTRAN IMPLEMENTATION

### 1. `compute_section_properties.f`

This subroutine computes the geometric properties of a cross-section from a 2D triangular mesh.

```fortran
subroutine compute_section_properties(nnode_sec, ntri_sec,
     &                                conn_sec, y_sec, z_sec,
     &                                E, G,
     &                                A, y_c, z_c,
     &                                I_y, I_z, I_yz, J_approx)
Arguments:

Argument	Intent	Description
nnode_sec	IN	Number of nodes in section mesh
ntri_sec	IN	Number of triangles in section mesh
conn_sec(3, ntri_sec)	IN	Triangle connectivity (node indices)
y_sec(nnode_sec)	IN	X-coordinates of nodes
z_sec(nnode_sec)	IN	Y-coordinates of nodes
E, G	IN	Material properties (unused in geometry, kept for API consistency)
A	OUT	Cross-sectional area
y_c, z_c	OUT	Centroid coordinates
I_y, I_z	OUT	Moments of inertia about centroidal axes
I_yz	OUT	Product of inertia about centroidal axes
J_approx	OUT	Approximate torsion constant (I_y + I_z)
Algorithm Walkthrough:

Initialisation: All accumulators are set to zero.

Triangle Loop: For each triangle, the subroutine:

Extracts nodal coordinates from the input arrays

Computes triangle area using the determinant formula

Calculates the triangle centroid (average of vertices)

Accumulates total area and first moments

Computes local moments of inertia using the standard triangle formula

Adds local contributions to global sums

Centroid Calculation: Divides first moments by total area.

Parallel Axis Theorem: Shifts inertia tensors from global axes to centroidal axes using the Huygens-Steiner theorem:

I_y = I_y_global - A·z_c²

I_z = I_z_global - A·y_c²

I_yz = I_yz_global - A·y_c·z_c

Approximate J: Computes J_approx = I_y + I_z (placeholder for exact Saint-Venant torsion solution).

Numerical Accuracy: The subroutine includes error checking for zero area and negative moments of inertia, issuing warnings when numerical issues are detected.

2. read_section_mesh_unv.f
This subroutine reads a 2D mesh from an I-DEAS Universal File (.unv) format.

fortran
subroutine read_section_mesh_unv(filename,
     &                           nnode_max, ntri_max,
     &                           nnode, ntri,
     &                           nodes, conn)
UNV File Format:

The I-DEAS Universal File format uses a simple delimiter-based structure:

text
    -1                    ! Section separator
  2411                    ! Node section marker
  node_id    x    y    z   ! Node data (one per line)
    -1                    ! End of node section
  2412                    ! Element section marker
  element_id    type    property    colour
  n1    n2    n3          ! Connectivity for triangle (type 41)
    -1                    ! End of element section
    -1                    ! End of file
Algorithm Walkthrough:

File Opening: Attempts to open the specified file; returns error if not found.

Parser State Machine: Uses flags reading_nodes and reading_elements to track the current section.

Section 2411 (Nodes):

Reads node ID and coordinates (x, y, z)

Stores coordinates in the nodes array

Z-coordinate is set to zero for 2D sections

Section 2412 (Elements):

Reads element header (ID, type, property, colour)

For element type 41 (3-node triangle), reads three node indices

Stores connectivity in the conn array

Skips other element types (44 for quadrilaterals, 111 for tetrahedra)

File Closure: Closes the file and returns the node and triangle counts.

Supported Element Types:

Type	Description	Support
41	3-node triangle	✓ Fully supported
44	4-node quadrilateral	✗ Skipped (not implemented)
111	4-node tetrahedron	✗ Skipped (not implemented)
3. section_database.f
This module provides a complete database system for managing multiple cross-sections.

Module Structure:

fortran
module section_database
  
  type :: section_props
    integer :: id
    character(len=256) :: filename
    character(len=50) :: name
    double precision :: A, y_c, z_c
    double precision :: I_y, I_z, I_yz
    double precision :: J, y_s, z_s
    double precision :: k_y, k_z
    double precision :: E, G
    logical :: is_loaded
  end type section_props
  
  type(section_props), save :: sections(MAX_SECTIONS)
  integer, save :: num_sections = 0
  
contains
  ! Subroutines documented below
end module section_database
Public Subroutines:

Subroutine	Purpose
init_section_database()	Initialises all section properties to default values
add_section(filename, name, E, G, section_id)	Loads a section from UNV file and adds to database
get_section_props(section_id, props)	Retrieves properties for a given section ID
list_all_sections()	Prints all sections in the database
Key Features:

Duplicate Prevention: If the same UNV file is loaded multiple times, the database returns the existing section ID without re-reading the mesh.

Automatic Property Computation: When a new section is added, the subroutine automatically:

Reads the mesh from the UNV file
Computes geometric properties
Stores the results in the database
Memory Efficiency: Maximum of 100 sections can be stored (configurable via MAX_SECTIONS parameter).

Database Workflow:

text
add_section(filename, name, E, G, section_id)
    │
    ├── Check if filename already in database
    │       │
    │       ├── YES → return existing section_id
    │       │
    │       └── NO → continue
    │
    ├── Allocate temporary arrays (nodes, conn)
    │
    ├── Call read_section_mesh_unv()
    │
    ├── Call compute_section_properties()
    │
    ├── Store properties in sections(num_sections)
    │
    └── Return new section_id
COMPILATION AND TESTING
Prerequisites
GNU Fortran (gfortran) version 4.8 or later

Make utility (optional)

Compilation Commands
Individual Compilation:

bash
# Compile source modules
gfortran -c src/compute_section_properties.f
gfortran -c src/read_section_mesh_unv.f
gfortran -c src/section_database.f

# Compile and link test programs
gfortran -c tests/test_section.f -o test_section.o
gfortran -o test_section test_section.o compute_section_properties.o

gfortran -c tests/test_unv_reader.f -o test_unv_reader.o
gfortran -o test_unv_reader test_unv_reader.o read_section_mesh_unv.o compute_section_properties.o

gfortran -c tests/test_multi_section.f -o test_multi_section.o
gfortran -o test_multi_section test_multi_section.o section_database.o read_section_mesh_unv.o compute_section_properties.o
Using Makefile:

bash
# Compile everything
make all

# Run all tests
make test

# Clean object files and executables
make clean
Makefile Structure
makefile
FC = gfortran
FFLAGS = -Wall -O2

all: test_section test_unv_reader test_multi_section

test_section: compute_section_properties.o tests/test_section.f
	$(FC) $(FFLAGS) -c tests/test_section.f -o test_section.o
	$(FC) $(FFLAGS) -o test_section test_section.o compute_section_properties.o

# Additional targets omitted for brevity
USAGE EXAMPLES
Example 1: Computing Properties of a Rectangle
fortran
program example_rectangle
  use section_database
  implicit none
  
  integer :: section_id
  type(section_props) :: props
  double precision :: E, G
  
  E = 210.0d9   ! Young's modulus for steel (Pa)
  G = 80.769d9  ! Shear modulus for steel (Pa)
  
  ! Initialise database
  call init_section_database()
  
  ! Load rectangle section
  call add_section('rect_10x20.unv', 'Rectangle 10x20', E, G, section_id)
  
  ! Retrieve properties
  call get_section_props(section_id, props)
  
  ! Display results
  write(*,*) 'Area      = ', props%A
  write(*,*) 'Centroid  = (', props%y_c, ',', props%z_c, ')'
  write(*,*) 'I_y       = ', props%I_y
  write(*,*) 'I_z       = ', props%I_z
  write(*,*) 'I_yz      = ', props%I_yz
end program
Example 2: Loading Multiple Sections
fortran
program example_multi_section
  use section_database
  implicit none
  
  integer :: id_rect, id_circle, id_heb
  type(section_props) :: props
  double precision :: E, G
  
  E = 210.0d9
  G = 80.769d9
  
  call init_section_database()
  
  ! Load three different sections
  call add_section('rect_10x20.unv', 'RECTANGLE', E, G, id_rect)
  call add_section('circle_dia10.unv', 'CIRCLE', E, G, id_circle)
  call add_section('heb240.unv', 'HEB240', E, G, id_heb)
  
  ! List all sections
  call list_all_sections()
  
  ! Access individual section
  call get_section_props(id_circle, props)
  write(*,*) 'Circle area: ', props%A
end program
Example 3: Creating a UNV Mesh File
A rectangular mesh file (rect_10x20.unv) has the following structure:

text
    -1
  2411
     1   0.0000000E+00   0.0000000E+00   0.0000000E+00
     2   1.0000000E+01   0.0000000E+00   0.0000000E+00
     3   1.0000000E+01   2.0000000E+01   0.0000000E+00
     4   0.0000000E+00   2.0000000E+01   0.0000000E+00
    -1
  2412
     1    41     1     0
     1     2     3
     2    41     1     0
     1     3     4
    -1
    -1
TEST RESULTS
Test 1: Rectangle 10×20
Property	Computed Value	Expected Value	Error
Area (A)	200.00000000000000	200.00000000000000	0.00%
Centroid (y_c, z_c)	(5.00, 10.00)	(5.00, 10.00)	0.00%
I_y	6666.6666666666606	6666.6666666666670	9.55×10⁻¹⁴%
I_z	1666.6666666666652	1666.6666666666667	9.55×10⁻¹⁴%
I_yz	-3.6379788070917130×10⁻¹²	0	~10⁻¹²
J_approx	8333.3333333333248	-	-
Result: PASSED ✓

Test 2: Circle (Diameter = 10)
Property	Computed Value	Expected Value	Error
Area (A)	77.254248098210127	78.53981633974483	-1.64%
I_y = I_z	474.96177249870442	490.8738521234052	-3.24%
J_approx	949.92354499740884	981.7477042468104	-3.24%
Note: Errors are due to mesh coarseness (only 20 triangles). Refining the mesh improves accuracy.

Test 3: UNV File Reader
Test	Result
File opening	✓ Success
Node reading (4 nodes)	✓ Correct coordinates
Triangle reading (2 triangles)	✓ Correct connectivity
Property computation	✓ Matches reference
Result: PASSED ✓

Test 4: Multi-Section Database
Test	Result
Database initialisation	✓ Success
Section addition (3 sections)	✓ All loaded
Duplicate file detection	✓ Same file loaded once
Property retrieval by ID	✓ Correct properties returned
Result: PASSED ✓

FUTURE DEVELOPMENTS
The following features are planned for future releases:

Phase 1: Exact Torsion Constant (Saint-Venant)
Implementation of a 2D FEM solver for the Poisson equation:

text
∇²ψ = -2
J = 2∫ψ dA
Required files:

assemble_poisson_2d.f - Assembles stiffness matrix and RHS vector

triangle_stiffness.f - Computes element stiffness for 3-node triangle

apply_dirichlet_bc.f - Applies ψ=0 on boundary nodes

solve_linear_system.f - Linear system solver (banded Cholesky)

Phase 2: Shear Centre Calculation
Implementation of two auxiliary problems for unit shear forces:

text
Vy = 1 → f = z
Vz = 1 → f = -y
y_s = -M_torque_case1 / Vy
z_s = M_torque_case2 / Vz
Phase 3: Shear Correction Factors
Computation of k_y and k_z factors for Timoshenko beam theory.

Phase 4: CalculiX Integration
Modification of e_c3d_u.f to dispatch to BEAMGEN element type

Implementation of beam_general_element.f with:

3-node quadratic beam element (18 DOF)

B-matrix formulation

Constitutive matrix D(6,6)

Global stiffness matrix assembly

Phase 5: Full Constitutive Matrix D(6,6)
Construction of the complete 6×6 constitutive matrix:

text
D = [ EA     0       0       0     -EA·e_z   EA·e_y  ]
    [ 0    k_y·G·A   0       0        0        0     ]
    [ 0       0    k_z·G·A   0        0        0     ]
    [ 0       0       0     G·J       0        0     ]
    [ -EA·e_z 0       0       0     E·I_z   E·I_yz  ]
    [ EA·e_y  0       0       0     E·I_yz   E·I_y   ]
Where:

e_y = y_s - y_c (offset between shear centre and centroid)

e_z = z_s - z_c

CONCLUSION
The Beam Section Properties Tool provides a robust, extensible foundation for computing cross-sectional properties from 2D triangular meshes. The modular architecture, comprehensive test suite, and detailed documentation make it suitable for integration into larger finite element analysis workflows, particularly with the CalculiX solver.

All code is released under the MIT License, encouraging open-source collaboration and further development.

REFERENCES
Beer, F.P., Johnston, E.R., DeWolf, J.T., & Mazurek, D.F. (2012). Mechanics of Materials, 6th Edition. McGraw-Hill.

Zienkiewicz, O.C., Taylor, R.L., & Zhu, J.Z. (2013). The Finite Element Method: Its Basis and Fundamentals, 7th Edition. Butterworth-Heinemann.

CalculiX User's Manual. www.calculix.de

I-DEAS Universal File Format Specification. Siemens PLM Software.

Document prepared on 10 April 2026
Authors: Bruno Zilli & DeepSeek
