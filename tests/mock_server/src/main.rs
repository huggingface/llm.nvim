use axum::{extract::State, routing::post, Json, Router};
use serde::{Deserialize, Serialize};
use std::{net::SocketAddr, sync::Arc};
use tokio::sync::Mutex;

#[derive(Clone)]
struct AppState {
    counter: Arc<Mutex<u32>>,
}

#[derive(Deserialize, Serialize)]
struct GeneratedText {
    generated_text: String,
}

async fn handler(state: State<AppState>) -> Json<Vec<GeneratedText>> {
    let mut lock = state.counter.lock().await;
    *lock += 1;
    println!("got request {}", lock);
    Json(vec![GeneratedText {
        generated_text: "dummy".to_owned(),
    }])
}

#[tokio::main]
async fn main() {
    let app_state = AppState {
        counter: Arc::new(Mutex::new(0)),
    };
    let app = Router::new()
        .route("/", post(handler))
        .with_state(app_state);
    let addr: SocketAddr = format!("{}:{}", "0.0.0.0", 4242)
        .parse()
        .expect("string to parse to socket addr");
    println!("starting server {}:{}", addr.ip().to_string(), addr.port(),);

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .expect("server to start");
}
