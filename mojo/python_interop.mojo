from std.python import Python

def main() raises:
    # Mojo makes it incredibly easy to use Python libraries
    var np = Python.import_module("numpy")

    var a = np.array([1, 2, 3])
    var b = np.array([4, 5, 6])

    print("Numpy addition from Mojo:", a + b)

    var plt = Python.import_module("matplotlib.pyplot")
    print("Successfully imported matplotlib too!")
