package schemes

List :: struct($T: typeid) {
	data:  []T,
	index: u32,
}

head :: proc(l: List($T)) -> T {
	return l.data[l.index]
}

tail :: proc(l: List($T)) -> List(T) {
	return List(T){data = l.data, index = l.index + 1}
}

is_empty :: proc(l: List($T)) -> bool {
	return l.index >= u32(len(l.data))
}

cata_lists :: proc(l: List($T), alg: proc(h: T, t: $R) -> R, base: R) -> R {
	if is_empty(l) {
		return base
	}

	isa := is_alg_associative(alg, head(l), head(tail(l)), head(tail(tail(l))))
	if isa {
		return cata_list(l, alg, base) // replace with foldr
	} else {
		return cata_list(l, alg, base)
	}
}


cata_list :: proc(l: List($T), alg: proc(h: T, t: $R) -> R, base: R) -> R {
	if is_empty(l) {
		return base
	}
	return alg(head(l), cata_list(tail(l), alg, base))


}

is_alg_associative :: proc(alg: proc(a: $T, b: T) -> T, x: T, y: T, z: T) -> bool {
	return alg(x, alg(y, z)) == alg(alg(x, y), z)
}

is_alg_commutative :: proc(alg: proc(a: $T, b: T) -> T, x: T, y: T) -> bool {
	return alg(x, y) == alg(y, x)
}

is_alg_idempotent :: proc(alg: proc(a: $T, b: T) -> T, x: T) -> bool {
	return alg(x, x) == x
}

list_sum :: proc(l: List(i32)) -> i32 {
	return cata_list(l, proc(h: i32, t: i32) -> i32 {return h + t}, 0)
}
