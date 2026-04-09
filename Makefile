# Makefile for Beam Section Tool
# Authors: Bruno Zilli & DeepSeek
# License: MIT
# Copyright (c) 2025 Bruno Zilli & DeepSeek
#
#
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#     
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#     
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
