// Example: Data-Oriented Game Entity Pipeline in Aloha (Rust--)
// Demonstrates Zero Lifetimes, Tagged Enums, and Direct rustc Compilation

struct Vector3 {
    x: f32,
    y: f32,
    z: f32,
}

struct RigidBody {
    position: Vector3,
    velocity: Vector3,
    mass: f32,
    entity_id: u32,
}

enum EntityKind {
    Player,
    Enemy(u32),
    Projectile(f32),
}

fn describe_entity(kind: &EntityKind) {
    match kind {
        EntityKind::Player => {
            println!("Entity Kind: Hero Player");
        }
        EntityKind::Enemy(level) => {
            println!("Entity Kind: Enemy Level {}", *level);
        }
        EntityKind::Projectile(speed) => {
            println!("Entity Kind: Projectile Speed {}", *speed);
        }
    }
}

fn update_position(body: &mut RigidBody, delta_time: f32) {
    body.position.x = body.position.x + body.velocity.x * delta_time;
    body.position.y = body.position.y + body.velocity.y * delta_time;
    body.position.z = body.position.z + body.velocity.z * delta_time;
}

fn apply_force(body: &mut RigidBody, force_x: f32, force_y: f32) {
    let accel_x = force_x / body.mass;
    let accel_y = force_y / body.mass;
    body.velocity.x = body.velocity.x + accel_x;
    body.velocity.y = body.velocity.y + accel_y;
}

fn main() {
    let mut body = RigidBody {
        position: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
        velocity: Vector3 { x: 10.0, y: 5.0, z: 0.0 },
        mass: 2.0,
        entity_id: 42,
    };

    let player_kind = EntityKind::Player;
    let enemy_kind = EntityKind::Enemy(5);
    let projectile_kind = EntityKind::Projectile(300.0);

    println!("=== Aloha Physics Simulation ===");
    println!("Initial Entity ID: {}", body.entity_id);
    println!("Initial Pos: ({}, {}, {})", body.position.x, body.position.y, body.position.z);
    println!("Initial Vel: ({}, {}, {})", body.velocity.x, body.velocity.y, body.velocity.z);

    describe_entity(&player_kind);
    describe_entity(&enemy_kind);
    describe_entity(&projectile_kind);

    apply_force(&mut body, 20.0, 10.0);
    update_position(&mut body, 0.5);

    println!("--- After Applying Force & Simulating 0.5s ---");
    println!("Final Pos: ({}, {}, {})", body.position.x, body.position.y, body.position.z);
    println!("Final Vel: ({}, {}, {})", body.velocity.x, body.velocity.y, body.velocity.z);
}
