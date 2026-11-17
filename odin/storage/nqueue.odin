package storage

import "core:fmt"

L1_Cache_Line_Size :: 64 // bytes

NQueue :: struct {
	data:     [L1_Cache_Line_Size]u8,
	children: [8]^NQueue,
}

main :: proc() {

}
