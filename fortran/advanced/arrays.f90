program array_demo
  implicit none
  integer, allocatable :: arr(:,:)
  
  print *, "--- 1. Fortran Array Demo ---"
  allocate(arr(3,3))
  arr = 0
  arr(1,:) = [1, 2, 3]  ! Slice assignment
  
  print *, "Row 1:", arr(1,:)
  deallocate(arr)
end program array_demo
