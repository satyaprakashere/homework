class Problem14S {
    fun longestCommonPrefix(strs: Array<String>): String {
        if (strs.isEmpty()) return ""
        var commonPrefix = strs[0]
        for (i in 1 until strs.size) { // Fix: Proper range for iteration
            while (!strs[i].startsWith(commonPrefix)) {
                if (commonPrefix.isEmpty()) return "" // If commonPrefix is empty, return immediately
                commonPrefix = commonPrefix.substring(0, commonPrefix.length - 1) // Fix: Proper method call
            }
        }
        return commonPrefix
    }
}

fun main() {
    val solution = Problem14S()
    val input = arrayOf("flower", "flow", "flight") // Fix: Proper array initialization
    println(solution.longestCommonPrefix(input))
}
