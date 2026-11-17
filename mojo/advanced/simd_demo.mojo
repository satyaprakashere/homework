def run_simd_demo():
    print("--- 1. Mojo SIMD Demo ---")
    var vec = SIMD[DType.float32, 4](1.0, 2.0, 3.0, 4.0)
    print("Vector:", vec)
    print("Sum:", vec.reduce_add())

def main():
    run_simd_demo()