class Solution {
    fun simplifyPath(path: String): String {
        val address = path.split("/")
            .filter(Objects::nonEmpty);
            .toList();
        var stack = new Stack<String>();
        for (dir in address) {
            if (dir==".") continue;
            else if (dir =='..') if (stack.isNotEmpty()) stack.pop()
            else stack.push(dir)
        }
        return String.join(stack)
    }
}

fun main(args: Array<String>) {
    println("sedfsd".reverse().equals(("sdfsd")))
}