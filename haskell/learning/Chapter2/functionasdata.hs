data Tree = Leaf String | Node Tree String Tree

tree = Node (Node (Leaf "1") "2" (Leaf "3")) "4" (Leaf "5")

show1 :: Tree -> String
show1 (Leaf s) = s
show1 (Node l s r) = show1 l ++ s ++ show1 r

--show11 :: Tree -> String
--show11 (Leaf s) k = k s
--show11 (Node l s r) k = show11 l (\x -> ++ s ++ show1 r

show2 :: Tree -> (String -> a) -> a
show2 (Leaf s) k = k s
show2 (Node l s r) k = show2 l (\ls ->
    show2 r (\rs ->
        k (ls ++ s ++ rs)))

done s = s
next (s, r, k) ls = show3 r (conc (ls, s, k))
conc (ls, s, k) rs = k (ls ++ s ++ rs)

show3 :: Tree -> (String -> a) -> a
show3 (Leaf s) k = k s
show3 (Node l s r) k = show3 l (next (s, r, k))

data Cont = Done | Next String Tree Cont | Conc String String Cont

apply :: Cont -> String -> String
apply Done s = s
apply (Next s r k) l = show4 r (Conc l s k)
apply (Conc l s k) r = apply k (l ++ s ++ r)

show4 :: Tree -> Cont -> String
show4 (Leaf s) k = apply k s
show4 (Node l s r) k = show4 l (Next s r k)


type Kont = [(String, Either Tree String)]

apply1 :: Kont -> String -> String
apply1 [] s = s
apply1 ((s, Left r):k) l = show5 r ((l, Right s):k)
apply1 ((l, Right s):k) r = apply1 k (l ++ s ++ r)

show5 :: Tree -> Kont -> String
show5 (Leaf s) k = apply1 k s
show5 (Node l s r) k = show5 l ((s, Left r):k)

test = do
    print $ show1 tree    
--    print $ show11 tree
    print $ show2 tree id
    print $ show3 tree done
    print $ show4 tree Done
    print $ show5 tree []

main = test