//go:build ignore
package main

import "fmt"

func main() {
    fmt.Println()
}

type ListNode struct {
    Val int
    Next *ListNode
}
 
func mergeTwoLists(list1 *ListNode, list2 *ListNode) *ListNode {
    head := &ListNode{}
    res := head

    for list1 != nil && list2 != nil {
        if list1.Val <= list2.Val {
            res.Next = list1
            list1 = list1.Next
        } else {
            res.Next = list2
            list2 = list2.Next
        }
        res = res.Next
    }
    
    if list1 != nil {
        res.Next = list1
    }
    
    if list2 != nil {
        res.Next = list2
    }
    
    return head.Next
}