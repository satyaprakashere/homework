from std.utils.index import Index
from std.algorithm import vectorize
from std.sys.info import simd_width_of

comptime type = DType.float32
comptime size = 1024
comptime simd_width = simd_width_of[type]()

def main():
    # SIMD (Single Instruction, Multiple Data) is built-in
    var v1 = SIMD[type, simd_width](1.0)
    var v2 = SIMD[type, simd_width](2.0)

    var result = v1 + v2
    print("SIMD Result:", result)

    # Simple vectorization example
    # Note: This is a conceptual snippet showing how Mojo handles low-level ops
    print("Mojo excels at hardware-level optimisations like this.")

