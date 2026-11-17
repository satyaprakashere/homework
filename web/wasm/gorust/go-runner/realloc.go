package main

/*
#include <stdlib.h>
*/
import "C"
import "unsafe"

//export cabi_realloc
func cabi_realloc(ptr unsafe.Pointer, origSize, align, newSize uintptr) unsafe.Pointer {
	if newSize == 0 {
		if ptr != nil {
			C.free(ptr)
		}
		return nil
	}
	if ptr == nil {
		return C.malloc(C.size_t(newSize))
	}
	return C.realloc(ptr, C.size_t(newSize))
}
