class ListNode(var value: Int) {
    var next: ListNode? = null
}

class Problem2 {
    var carry = 0
    fun addTwoNumbers(l1: ListNode?, l2: ListNode?): ListNode? {
        val result = ListNode(0)
        addTwoNumbersH(l1, l2, result)
        return result.next
    }

    tailrec fun addTwoNumbersH(l1: ListNode?, l2: ListNode?, res: ListNode?) {
        if (l1 == null && l2 == null && carry == 0) {
            return
        }

        val sum = (l1?.value ?: 0) + (l2?.value ?: 0) + carry
        carry = sum / 10
        res?.next = ListNode(sum % 10)

        return addTwoNumbersH(l1?.next, l2?.next, res?.next)
    }
}

fun main() {
    var result = Problem2().addTwoNumbers(ListNode(2).apply { next = ListNode(4).apply { next = ListNode(3) } },
        ListNode(5).apply { next = ListNode(6).apply { next = ListNode(4) } })

    while (result != null) {
        print("${result.value} : ")
        result = result.next
    }
}
