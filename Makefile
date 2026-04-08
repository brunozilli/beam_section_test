# Makefile for Beam Section Tool
# Authors: Bruno Zilli & DeepSeek
# Licence: MIT

FC = gfortran
FFLAGS = -Wall -O2
TARGETS = test_section test_unv_reader test_multi_section

OBJS = compute_section_properties.o \
       read_section_mesh_unv.o \
       section_database.o \
       mesh_checker.o

all: $(TARGETS)

test_section: tests/test_section.f compute_section_properties.o
$(FC) $(FFLAGS) -o $@ $^

test_unv_reader: tests/test_unv_reader.f read_section_mesh_unv.o compute_section_properties.o
$(FC) $(FFLAGS) -o $@ $^

test_multi_section: tests/test_multi_section.f $(OBJS)
$(FC) $(FFLAGS) -o $@ $^

%.o: src/%.f
$(FC) $(FFLAGS) -c $< -o $@

clean:
rm -f *.o *.mod $(TARGETS)

.PHONY: all clean
