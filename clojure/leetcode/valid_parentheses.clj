(ns leetcode.valid-parentheses)

;; Valid Parentheses
;; Given a string s containing just the characters '(', ')', '{', '}', '[' and ']',
;; determine if the input string is valid.

(def pairs {\) \(
             \} \{
             \] \[})

(defn valid-parentheses? [s]
  (loop [chars (seq s)
         stack '()] ; Clojure lists are perfect as stacks (push is conj, pop is rest/pop)
    (if (empty? chars)
      (empty? stack)
      (let [c (first chars)]
        (if (contains? pairs c) ; It's a closing bracket
          (if (= (first stack) (get pairs c))
            (recur (rest chars) (rest stack)) ; Match found, pop
            false) ; Mismatch
          (recur (rest chars) (conj stack c))))))) ; It's an opening bracket, push

;; Test cases
(println "Valid '()':" (valid-parentheses? "()"))             ; Expected: true
(println "Valid '()[]{}':" (valid-parentheses? "()[]{}"))     ; Expected: true
(println "Valid '(]':" (valid-parentheses? "(]"))             ; Expected: false
(println "Valid '([)]':" (valid-parentheses? "([)]"))         ; Expected: false
(println "Valid '{[]}':" (valid-parentheses? "{[]}"))         ; Expected: true
