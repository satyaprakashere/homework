use axum::{
    routing::get,
    Router,
};
use std::net::SocketAddr;
use tokio::task;

#[tokio::main]
async fn main() {
    let start_port = 8000;
    let end_port = 8999; // change to 8999 for 1000 servers

    for port in start_port..=end_port {
        task::spawn(start_server(port));
    }

    // Keep main alive
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
    }
}

async fn start_server(port: u16) {
    let app = Router::new().route("/", get(move || async move {
        format!("Hello from port {}", port)
    }));

    let addr = SocketAddr::from(([127, 0, 0, 1], port));

    let listener = match tokio::net::TcpListener::bind(addr).await {
        Ok(listener) => listener,
        Err(err) => {
            eprintln!("Failed to bind to port {}: {}", port, err);
            return;
        }
    };

    println!("Listening on http://{}", addr);

    if let Err(err) = axum::serve(listener, app).await {
        eprintln!("Server on port {} failed: {}", port, err);
    }
}
