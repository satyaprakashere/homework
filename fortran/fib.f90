program fibonacci_example
    implicit none

    integer :: n, i
    integer(kind=8), dimension(:), allocatable :: fib  ! 64-bit integers for larger numbers

    print *, "How many Fibonacci numbers would you like to generate?"
    read *, n

    if (n <= 0) then
        print *, "Please enter a positive integer."
        stop
    end if

    ! Allocate an array to store the sequence
    allocate(fib(n))

    ! Initializing the first two terms
    if (n >= 1) fib(1) = 0
    if (n >= 2) fib(2) = 1

    ! Calculating the sequence using a DO loop
    do i = 3, n
        fib(i) = fib(i-1) + fib(i-2)
    end do

    ! Printing the results
    print *, "The Fibonacci sequence is:"
    do i = 1, n
        print '(I0, " ")', fib(i)
    end do

    deallocate(fib)

end program fibonacci_example