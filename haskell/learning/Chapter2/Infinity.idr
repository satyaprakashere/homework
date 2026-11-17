module Main

data Vect : Nat -> Type -> Type where
    VNil  : Vect Z a
    (::)  : a -> Vect k a -> Vect (S k) a

data SimpleNumber : Nat -> Type where
    IntegerNumber : (a: Integer) -> SimpleNumber Z
    LinearNumber  : (a: Integer) -> (b: Nat) -> SimpleNumber (plus 1 (div b 10))

(Show Integer, Show Nat) => Show (SimpleNumber n) where
    show (IntegerNumber a)  = show a
    show (LinearNumber a b) = show a ++ "." ++ show b

Show a => Show (Vect n a) where
    show xs = "[" ++ show' xs ++ "]" where
        show' : Vect n a -> String
        show' VNil            = ""
        show' (x::VNil)   = show x
        show' (x::xs)     = show x ++ ", " ++ show' xs

main : IO ()
main = do
    putStrLn "Hello World"
    printLn (1::2::VNil)
    printLn (LinearNumber 100 100)
    printLn (LinearNumber 434 2543)