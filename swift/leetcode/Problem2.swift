
class ListNode {
    var val: Int
    var next: ListNode?
    init() { self.val = 0; self.next = nil; }
    init(_ val: Int) { self.val = val; self.next = nil; }
    init(_ val: Int, _ next: ListNode?) { self.val = val; self.next = next; }
}

class Solution {
    var carry = 0
    func addTwoNumbers(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {
        // guard l1 || l2 || carry > 0 {}
        guard l1 != nil || l2 != nil || carry != 0 else {
            return nil
        }
        // let sum = l1.val.orElse(0) ...
        // let sum = l1.val(0) ...
        
        let sum = (l1?.val ?? 0) + (l2?.val ?? 0) + carry
        carry = sum / 10
        return .init(sum % 10, addTwoNumbers(l1?.next, l2?.next))
    }
}

var res = Solution().addTwoNumbers(ListNode.init(4), ListNode.init(5))?.val ?? -1

print(res)
