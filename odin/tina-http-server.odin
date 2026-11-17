package main

import http "deps/tina/src/extensions/http/server"
import tina "deps/tina/src"

main :: proc() {
    app := http.App {
        routes =[]http.Route{
            http.get("/health", health),
            http.get("/users/:id", get_user),
        },
    }

    server := http.Server {
        address = tina.ipv4(0, 0, 0, 0, 8080),
        app     = &app,
    }

    // Installs HTTP isolates into a Tina SystemSpec (Single-shard dev mode)
    spec := http.install_development_defaults(&server)
    tina.tina_start(&spec)
}

health :: proc(request: ^http.Request, response: ^http.Response) -> http.Route_Step {
    return http.respond_text(response, http.HTTP_STATUS_OK, "ok")
}

get_user :: proc(request: ^http.Request, response: ^http.Response) -> http.Route_Step {
    id := http.param(request, "id")
    return http.respond_bytes(response, http.HTTP_STATUS_OK, "application/json", nil)
}