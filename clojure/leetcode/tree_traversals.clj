(ns leetcode.tree-traversals)

;; Tree structure: {:val val :left left-node :right right-node}

(def sample-tree
  {:val 1
   :left {:val 2 :left {:val 4} :right {:val 5}}
   :right {:val 3 :left {:val 6} :right {:val 7}}})

;; 1. In-order DFS (Recursive)
(defn inorder [node]
  (if (nil? node)
    []
    (concat (inorder (:left node))
            [(:val node)]
            (inorder (:right node)))))

;; 2. Breadth-First Search (BFS)
(defn bfs [root]
  (loop [queue (conj [] root) ; Use a vector as a simple queue
         result []]
    (if (empty? queue)
      result
      (let [node (first queue)
            remaining-queue (subvec queue 1)]
        (if (nil? node)
          (recur remaining-queue result)
          (recur (into remaining-queue [(:left node) (:right node)])
                 (conj result (:val node))))))))

;; 3. Depth-First Search (Iterative with stack)
(defn dfs-iterative [root]
  (loop [stack (list root)
         result []]
    (if (empty? stack)
      result
      (let [node (first stack)
            remaining-stack (rest stack)]
        (if (nil? node)
          (recur remaining-stack result)
          (recur (conj remaining-stack (:right node) (:left node)) ; Push right then left to process left first
                 (conj result (:val node))))))))

;; Test cases
(println "In-order DFS:" (inorder sample-tree))       ; Expected: (4 2 5 1 6 3 7)
(println "BFS (Level order):" (bfs sample-tree))     ; Expected: [1 2 3 4 5 6 7]
(println "DFS (Pre-order):" (dfs-iterative sample-tree)) ; Expected: [1 2 4 5 3 6 7]
