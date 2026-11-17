#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define PORT 8080
#define BUFFER_SIZE 4096

void handle_client(int client_fd) {
    char buffer[BUFFER_SIZE] = {0};
    
    // Read the incoming HTTP request
    ssize_t bytes_read = read(client_fd, buffer, BUFFER_SIZE - 1);
    if (bytes_read < 0) {
        perror("Failed to read from client socket");
        return;
    }

    // Print the request line for visibility (e.g., "GET / HTTP/1.1")
    printf("%.*s\n", (int)(strchr(buffer, '\n') ? strchr(buffer, '\n') - buffer : bytes_read), buffer);

    // Prepare HTTP response
    const char* body = "<html><body><h1>Hello from C!</h1></body></html>";
    char response[BUFFER_SIZE];
    
    int response_len = snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/html; charset=UTF-8\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "\r\n"
        "%s",
        strlen(body), body
    );

    // Send response back to the client
    write(client_fd, response, response_len);
}

int main(void) {
    int server_fd, client_fd;
    struct sockaddr_in address;
    int addrlen = sizeof(address);

    // 1. Create socket file descriptor
    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd == 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // Optional: Allow immediate reuse of the port after stopping the server
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    // 2. Bind socket to localhost:8080
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY; // 127.0.0.1
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        perror("Bind failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    // 3. Start listening for incoming connections
    if (listen(server_fd, 10) < 0) {
        perror("Listen failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    printf("HTTP server listening on http://127.0.0.1:%d\n", PORT);

    // 4. Main server loop
    while (1) {
        client_fd = accept(server_fd, (struct sockaddr*)&address, (socklen_t*)&addrlen);
        if (client_fd < 0) {
            perror("Accept failed");
            continue;
        }

        // Handle the client synchronously (for a simple blocking single-threaded model)
        handle_client(client_fd);

        // Close the connection
        close(client_fd);
    }

    close(server_fd);
    return 0;
}