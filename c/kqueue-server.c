#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/event.h>
#include <sys/time.h>
#include <netinet/in.h>

#define PORT 8080
#define MAX_EVENTS 64
#define BUFFER_SIZE 4096

// Set a socket to non-blocking mode
int make_non_blocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags == -1) return -1;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

int main(void) {
    int server_fd, kq;
    struct sockaddr_in address;

    // 1. Create listening socket
    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd == -1) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY; // Bind to all available interfaces
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) == -1) {
        perror("Bind failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, SOMAXCONN) == -1) {
        perror("Listen failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    make_non_blocking(server_fd);

    // 2. Create kqueue instance
    kq = kqueue();
    if (kq == -1) {
        perror("kqueue failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    // Register the server socket with kqueue to watch for read events (incoming connections)
    struct kevent change_event;
    EV_SET(&change_event, server_fd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);
    
    if (kevent(kq, &change_event, 1, NULL, 0, NULL) == -1) {
        perror("kevent registering server_fd failed");
        close(server_fd);
        close(kq);
        exit(EXIT_FAILURE);
    }

    struct kevent event_list[MAX_EVENTS];
    printf("macOS kqueue HTTP server listening on http://127.0.0.1:%d\n", PORT);

    // 3. Main Event Loop
    while (1) {
        int nev = kevent(kq, NULL, 0, event_list, MAX_EVENTS, NULL);
        if (nev == -1) {
            perror("kevent wait failed");
            break;
        }

        for (int i = 0; i < nev; i++) {
            int current_fd = (int)event_list[i].ident;

            // Check for errors on the event
            if (event_list[i].flags & EV_ERROR) {
                close(current_fd);
                continue;
            }

            if (current_fd == server_fd) {
                // ---- Handle New Incoming Connections ----
                struct sockaddr_in client_addr;
                socklen_t client_len = sizeof(client_addr);
                int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
                if (client_fd == -1) {
                    continue;
                }

                make_non_blocking(client_fd);

                // Register client socket with kqueue for read events
                EV_SET(&change_event, client_fd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);
                if (kevent(kq, &change_event, 1, NULL, 0, NULL) == -1) {
                    close(client_fd);
                }
            } else {
                // ---- Handle Data from an Existing Client ----
                char buffer[BUFFER_SIZE];
                ssize_t bytes_read = read(current_fd, buffer, sizeof(buffer) - 1);

                if (bytes_read <= 0) {
                    // Client closed connection or error
                    close(current_fd);
                } else {
                    // Construct HTTP response
                    const char* body = "<html><body><h1>Hello from macOS kqueue!</h1></body></html>";
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

                    write(current_fd, response, response_len);

                    // Close socket immediately after writing
                    close(current_fd);
                }
            }
        }
    }

    close(server_fd);
    close(kq);
    return 0;
}