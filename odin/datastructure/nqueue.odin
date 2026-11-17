package storage

import "core:fmt"

NQueue :: struct {
	data:     [64]u8,
	children: [8]^NQueue,
}

main :: proc() {

}
