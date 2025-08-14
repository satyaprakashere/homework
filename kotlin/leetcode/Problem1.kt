class Problem1 {
    fun twoSum(nums: IntArray, target: Int): IntArray {
        val map = nums.withIndex().associate { it.value to it.index }
        for ((i, e) in nums.withIndex()) {
            val sindex = map.get(target-e)
            if (sindex != null && sindex != i ) {
                return intArrayOf(i, sindex);
            }
        }
        return IntArray(0)
    }
}


fun main() {
    println(Problem1().twoSum(intArrayOf( 2, 7, 3, 11), 9).joinToString());
}
