c=======================================================================
c read_section_mesh_unv.f
c Reads UNV format: supports both simple and Salome formats
c
c Authors: Bruno Zilli & DeepSeek
c Licence: MIT
c=======================================================================

      subroutine read_section_mesh_unv(filename, max_nodes, 
     &                                 max_triangles, n_nodes, 
     &                                 n_triangles, conn, y, z)

      implicit none
      
      character(len=*), intent(in) :: filename
      integer, intent(in) :: max_nodes, max_triangles
      integer, intent(out) :: n_nodes, n_triangles
      integer, intent(out) :: conn(3, max_triangles)
      double precision, intent(out) :: y(max_nodes), z(max_nodes)
      
      integer :: io, node_id, elem_id, elem_type
      integer :: n1, n2, n3, dummy, phys_prop
      character(len=256) :: line
      logical :: in_nodes, in_elements, salome_format
      double precision :: x, yc, zc
      
      n_nodes = 0
      n_triangles = 0
      in_nodes = .false.
      in_elements = .false.
      salome_format = .false.
      
      open(10, file=filename, status='old', iostat=io)
      if (io .ne. 0) then
        print *, 'ERROR: Cannot open file ', filename
        return
      end if
      
      do
        read(10, '(A)', iostat=io) line
        if (io .ne. 0) exit
        
        if (index(line, '2411') .ne. 0) then
          in_nodes = .true.
          in_elements = .false.
c         Check if next line has 4 integers (Salome format)
          read(10, '(A)', iostat=io) line
          backspace(10)
          read(line, *, iostat=io) dummy, dummy, dummy, dummy
          if (io .eq. 0) salome_format = .true.
          cycle
        endif
        
        if (index(line, '2412') .ne. 0) then
          in_nodes = .false.
          in_elements = .true.
          cycle
        endif
        
        if (line .eq. '    -1' .or. line .eq. '-1') then
          in_nodes = .false.
          in_elements = .false.
          cycle
        endif
        
        if (in_nodes) then
          if (salome_format) then
c           Salome format: "id 1 1 11" then next line coordinates
            read(line, *, iostat=io) node_id, dummy, dummy, dummy
            if (io .eq. 0 .and. node_id .gt. 0) then
              read(10, *, iostat=io) x, yc, zc
              if (io .eq. 0) then
                n_nodes = n_nodes + 1
                if (n_nodes .le. max_nodes) then
                  y(n_nodes) = x
                  z(n_nodes) = yc
                endif
              endif
            endif
          else
c           Simple format: "id x y z" on same line
            read(line, *, iostat=io) node_id, x, yc, zc
            if (io .eq. 0 .and. node_id .gt. 0) then
              n_nodes = n_nodes + 1
              if (n_nodes .le. max_nodes) then
                y(n_nodes) = x
                z(n_nodes) = yc
              endif
            endif
          endif
          cycle
        endif
        
        if (in_elements) then
c         Element header: "id type phys_prop"
          read(line, *, iostat=io) elem_id, elem_type, phys_prop
          if (io .eq. 0 .and. elem_type .eq. 41) then
            n_triangles = n_triangles + 1
            if (n_triangles .le. max_triangles) then
              read(10, *) n1, n2, n3
              conn(1, n_triangles) = n1
              conn(2, n_triangles) = n2
              conn(3, n_triangles) = n3
            endif
          endif
        endif
      end do
      
      close(10)
      
      print *, 'Read mesh from: ', filename
      print *, '   Nodes:       ', n_nodes
      print *, '   Triangles:   ', n_triangles
      
      end subroutine read_section_mesh_unv
