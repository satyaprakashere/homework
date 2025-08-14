import Swift

print("Hello There to Swift Collections!")
let arr = testArrays()
let slice = testArraySlice(arr: arr)
let set = testSet(slice: slice)

func testArrays() -> Array<Int> {
    var arr = Array(repeating: 0, count: 10)
    let size = arr.count

    arr[size-1] = size

    print(size)
    for (i, e) in arr.enumerated() {
        print("Array ele at ", i, " = ", e)
    }
    return arr
}

func testArraySlice(arr: Array<Int>) -> ArraySlice<Int> {
    var slice = ArraySlice(arr)
    let size = slice.count

    slice[size-1] = size

    print(size)
    for (i, e) in slice.enumerated() {
        print("Slice ele at ", i, " = ", e)
    }
    return slice
}

func testSet(slice: ArraySlice<Int>) -> Set<Int> {
    let set = Set(slice)
    return set
}
