# lists.roc
# Run with: roc lists.roc
# Run tests with: roc test lists.roc
#
# Topics: List literals, common list methods, for loops, map, filter, fold
#
# KEY NOTES for this Roc nightly:
#   - Use .fold() not .walk()
#   - Use .keep_if() for filtering
#   - Use .sort() for sorting (no arguments)
#   - Booleans: True / False

# Helper: join a list of strings with a separator using fold
join_strs = |list, sep| {
    list.fold("", |acc, s| {
        if acc == "" { s } else { Str.concat(acc, Str.concat(sep, s)) }
    })
}

nums = [1, 2, 3, 4, 5]

# Common list operations (method-call style)
expect nums.len() == 5
expect nums.first() == Ok(1)
expect nums.last() == Ok(5)
expect nums.get(2) == Ok(3)       # 0-indexed
expect nums.contains(3) == True
expect [].is_empty() == True

# --- Building lists ---
expect nums.append(6) == [1, 2, 3, 4, 5, 6]
expect nums.prepend(0) == [0, 1, 2, 3, 4, 5]
expect [1, 2].concat([3, 4]) == [1, 2, 3, 4]

# reverse: fold+prepend since .reverse() isn't available in this nightly
manual_reverse = nums.fold([], |acc, n| acc.prepend(n))
expect manual_reverse == [5, 4, 3, 2, 1]

# --- Transforming lists ---

# map: apply a function to each element
doubled = nums.map(|n| n * 2)
expect doubled == [2, 4, 6, 8, 10]

# keep_if: keep only elements matching a predicate
evens = nums.keep_if(|n| n % 2 == 0)
expect evens == [2, 4]

# fold: accumulate a result across all elements
total = nums.fold(0, |acc, n| acc + n)
expect total == 15

# --- Sorting ---
unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
sorted = unsorted.sort()
expect sorted == [1, 1, 2, 3, 4, 5, 6, 9]

# --- Imperative style with for loop ---
sum_with_loop = |list| {
    var $acc = 0
    for n in list {
        $acc = $acc + n
    }
    $acc
}
expect sum_with_loop([1, 2, 3, 4, 5]) == 15

main! = |_args| {
    echo!("nums        = [${join_strs(nums.map(|n| n.to_str()), ", ")}]\n")
    echo!("doubled     = [${join_strs(doubled.map(|n| n.to_str()), ", ")}]\n")
    echo!("evens       = [${join_strs(evens.map(|n| n.to_str()), ", ")}]\n")
    echo!("sum         = ${total.to_str()}\n")
    echo!("sorted      = [${join_strs(sorted.map(|n| n.to_str()), ", ")}]\n")
    echo!("reversed    = [${join_strs(manual_reverse.map(|n| n.to_str()), ", ")}]\n")

    Ok({})
}
