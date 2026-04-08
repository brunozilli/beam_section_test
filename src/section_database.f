c=======================================================================
c section_database.f - CORRECTED VERSION
c Authors: Bruno Zilli & DeepSeek
c MIT License
c=======================================================================

      module section_database
      
      implicit none
      
c     Maximum number of different sections
      integer, parameter :: MAX_SECTIONS = 100
      
c     Maximum mesh size
      integer, parameter :: MAX_NODES = 10000
      integer, parameter :: MAX_TRIANGLES = 20000
      
c     Section property structure
      type :: section_props
        integer :: id
        character(len=256) :: filename
        character(len=50) :: name
        double precision :: A
        double precision :: y_c, z_c
        double precision :: I_y, I_z, I_yz
        double precision :: J
        double precision :: y_s, z_s
        double precision :: k_y, k_z
        double precision :: E, G
        logical :: is_loaded
      end type section_props
      
c     Global database
      type(section_props), save :: sections(MAX_SECTIONS)
      integer, save :: num_sections = 0
      
      contains
      
c=======================================================================
      subroutine init_section_database()
c=======================================================================
      implicit none
      integer :: i
      
      do i = 1, MAX_SECTIONS
        sections(i)%id = 0
        sections(i)%filename = ''
        sections(i)%name = ''
        sections(i)%A = 0.0d0
        sections(i)%y_c = 0.0d0
        sections(i)%z_c = 0.0d0
        sections(i)%I_y = 0.0d0
        sections(i)%I_z = 0.0d0
        sections(i)%I_yz = 0.0d0
        sections(i)%J = 0.0d0
        sections(i)%y_s = 0.0d0
        sections(i)%z_s = 0.0d0
        sections(i)%k_y = 1.0d0
        sections(i)%k_z = 1.0d0
        sections(i)%E = 0.0d0
        sections(i)%G = 0.0d0
        sections(i)%is_loaded = .false.
      end do
      
      num_sections = 0
      
      end subroutine init_section_database
      
c=======================================================================
       subroutine add_section(filename, section_name, E, G, section_id)
c=======================================================================
      implicit none
      character(len=*), intent(in) :: filename
      character(len=*), intent(in) :: section_name
      double precision, intent(in) :: E, G
      integer, intent(out) :: section_id
      
c     Local variables
      integer :: i, nnode, ntri
      double precision, allocatable :: nodes(:,:)
      integer, allocatable :: conn(:,:)
      double precision :: A, y_c, z_c, I_y, I_z, I_yz, J_approx
c     Variabili per mesh checker
      double precision :: A_total
      integer :: n_flipped, n_degenerate, ierr
      
c     Check if section already exists
      do i = 1, num_sections
        if (trim(sections(i)%filename) .eq. trim(filename)) then
          section_id = i
          return
        endif
      end do
      
c     Allocate temporary arrays
      allocate(nodes(3, MAX_NODES))
      allocate(conn(3, MAX_TRIANGLES))
      
c     Read mesh from UNV file
      call read_section_mesh_unv(filename, 
     &                           MAX_NODES, MAX_TRIANGLES,
     &                           nnode, ntri,
     &                           nodes, conn)
      
      if (ntri .eq. 0) then
        write(*,*) 'ERROR: No triangles found in file: ', filename
        section_id = -1
        deallocate(nodes, conn)
        return
      endif
      
c     ================================================================
c     CHECK AND FIX MESH (industrial grade)
c     ================================================================
      call check_and_fix_mesh(nnode, ntri, conn,
     &                        nodes(1,:), nodes(2,:),
     &                        A_total, n_flipped, n_degenerate, ierr)
      
      if (ierr .ne. 0) then
         write(*,*) 'ERROR: mesh validation failed for file: ', filename
         section_id = -1
         deallocate(nodes, conn)
         return
      endif
      
c     ================================================================
c     COMPUTE SECTION PROPERTIES
c     ================================================================
c     Compute section properties
      call compute_section_properties(nnode, ntri, conn,
     &                                nodes(1,:), nodes(2,:),
     &                                A, y_c, z_c,
     &                                I_y, I_z, I_yz, J_approx)
      
c     Add to database
      num_sections = num_sections + 1
      section_id = num_sections
      
      sections(section_id)%id = section_id
      sections(section_id)%filename = trim(filename)
      sections(section_id)%name = trim(section_name)
      sections(section_id)%A = A
      sections(section_id)%y_c = y_c
      sections(section_id)%z_c = z_c
      sections(section_id)%I_y = I_y
      sections(section_id)%I_z = I_z
      sections(section_id)%I_yz = I_yz
      sections(section_id)%J = J_approx
      sections(section_id)%y_s = y_c
      sections(section_id)%z_s = z_c
      sections(section_id)%E = E
      sections(section_id)%G = G
      sections(section_id)%is_loaded = .true.
      
c     Print summary
      write(*,*) 'Section added to database:'
      write(*,*) '  ID       = ', section_id
      write(*,*) '  Name     = ', trim(section_name)
      write(*,*) '  File     = ', trim(filename)
      write(*,*) '  Area     = ', A
      write(*,*) '  I_y      = ', I_y
      write(*,*) '  I_z      = ', I_z
      
c     Clean up
      deallocate(nodes, conn)
      
      end subroutine add_section
c=======================================================================
      subroutine get_section_props(section_id, props)
c=======================================================================
      implicit none
      integer, intent(in) :: section_id
      type(section_props), intent(out) :: props
      
      if (section_id .ge. 1 .and. section_id .le. num_sections) then
        props = sections(section_id)
      else
        write(*,*) 'ERROR: Invalid section ID: ', section_id
        props%is_loaded = .false.
      endif
      
      end subroutine get_section_props
      
c=======================================================================
      subroutine list_all_sections()
c=======================================================================
      implicit none
      integer :: i
      
      write(*,*)
      write(*,*) '=========================================='
      write(*,*) '  SECTION DATABASE'
      write(*,*) '=========================================='
      
      do i = 1, num_sections
        if (sections(i)%is_loaded) then
          write(*,*) 'ID: ', i, ' Name: ', trim(sections(i)%name)
          write(*,*) '     Area: ', sections(i)%A
          write(*,*) '     I_y:  ', sections(i)%I_y
          write(*,*) '     I_z:  ', sections(i)%I_z
          write(*,*)
        endif
      end do
      
      write(*,*) '=========================================='
      write(*,*)
      
      end subroutine list_all_sections
      
      end module section_database
