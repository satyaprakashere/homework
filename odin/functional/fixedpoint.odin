package main

import "core:fmt"

NodeID :: distinct int
Nil    :: NodeID(-1)

Cons :: struct($T: typeid) {
    x   : int,
    xs  : T,
}

NodeF :: struct($T: typeid) {
    variant: union {
        NodeID,
        Cons(T),
    },
}

mult_algebra :: proc(e: NodeF(int)) -> int {
    switch v in e.variant {
    case NodeID: return 1
    case Cons(int):
        return v.x * v.xs
    }
    return -1
}

// The 'Arena' that holds our recursive structure
Recursive_Pool :: struct($T: typeid) {
    nodes: [dynamic]T,
}

// Add a new node to the recursive structure
add_node :: proc(pool: ^Recursive_Pool(int), val: int) -> NodeID {
    idx := NodeID(len(pool.nodes))
    append(&pool.nodes, val)
    return idx
}

next :: proc(pool: ^Recursive_Pool(int), id: NodeID) -> NodeID{
    return id-1 == Nil ? Nil : NodeID(id-1)
}

main :: proc() {
    pool := Recursive_Pool(int){nodes = make([dynamic]int)}
    defer delete(pool.nodes)

    // Building [10, 20, 30] from tail to head
    // 30 points to nothing (Nil)
    idx30 := add_node(&pool, 30)
    idx20 := add_node(&pool, 20)
    idx10 := add_node(&pool, 10)

    // Traversal is now just array lookups
    curr := idx10
    for curr != Nil {
        node := pool.nodes[curr]
        fmt.print(node)
        
        if next(&pool, curr) != Nil {
            fmt.print(" -> ")
        }
        curr = next(&pool, curr)
    }
    fmt.println()
}

// cata: (ExprF(A) -> A) -> Expr -> A
// It collapses the recursive 'Expr' into a single value 'A'.
cata :: proc(node: ^Expr, algebra: proc(NodeF($A)) -> A) -> A {
    // 1. Recurse down: map 'cata' over children to turn them into 'A'
    mapped_layer: ExprF(A)
    
    switch v in node.derived.variant {
    case int:
        mapped_layer.variant = v
    case Cons(^Expr):
        mapped_layer.variant = Cons(A){
            x  = v.x,
            xs = cata(v.xs, algebra),
        }
    }
    
    // 2. Apply algebra to the results
    return algebra(mapped_layer)
}