#include <liburing.h>
#include <fcntl.h>
#include <iostream>

int main() {
    // Initialize io_uring with 32 entries
    io_uring ring;
    io_uring_queue_init(32, &ring, 0);
    
    // Open a file
    int fd = open("test.dat", O_RDWR | O_CREAT, 0644);
    if (fd < 0) {
        std::cerr << "Failed to open file" << std::endl;
        return 1;
    }
    
    // Prepare a write operation
    char buffer[] = "Testing io_uring";
    io_uring_sqe* sqe = io_uring_get_sqe(&ring);
    io_uring_prep_write(sqe, fd, buffer, sizeof(buffer) - 1, 0);
    
    // Submit the request
    io_uring_submit(&ring);
    
    // Wait for completion
    io_uring_cqe* cqe;
    io_uring_wait_cqe(&ring, &cqe);
    
    // Check result
    if (cqe->res < 0) {
        std::cerr << "Write failed: " << strerror(-cqe->res) << std::endl;
    } else {
        std::cout << "Wrote " << cqe->res << " bytes" << std::endl;
    }
    
    // Mark as seen
    io_uring_cqe_seen(&ring, cqe);
    
    // Cleanup
    close(fd);
    io_uring_queue_exit(&ring);
    
    return 0;
}
