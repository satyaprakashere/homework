fun findMedianSortedArrays(nums1: IntArray, nums2: IntArray): Double {
    // Ensure nums1 is the shorter array
    val (A, B) = if (nums1.size <= nums2.size) nums1 to nums2 else nums2 to nums1
    val m = A.size
    val n = B.size
    
    var low = 0
    var high = m
    
    while (low <= high) {
        val i = (low + high) / 2
        val j = (m + n + 1) / 2 - i
        
        val A_left = if (i == 0) Int.MIN_VALUE else A[i - 1]
        val A_right = if (i == m) Int.MAX_VALUE else A[i]
        val B_left = if (j == 0) Int.MIN_VALUE else B[j - 1]
        val B_right = if (j == n) Int.MAX_VALUE else B[j]
        
        if (A_left <= B_right && B_left <= A_right) {
            // Found correct partition
            return if ((m + n) % 2 == 0)
                (maxOf(A_left, B_left) + minOf(A_right, B_right)) / 2.0
            else
                maxOf(A_left, B_left).toDouble()
        } else if (A_left > B_right) {
            high = i - 1
        } else {
            low = i + 1
        }
    }
    
    throw IllegalArgumentException("Input arrays not sorted properly.")
}

fun main() {
    println(findMedianSortedArrays(intArrayOf(1, 2, 3, 4),intArrayOf(3, 5, 6, 7)))
}