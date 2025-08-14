data Matrix = Nat -> Nat -> Type -> Type where
  Matrix n m a : Vect n (Vect m a)

interface MatrixOp Num a => (mat : n -> m -> a -> Type) where
  (+) : (mat n m a) -> (mat n m a) -> (mat n m a)
  (-) : (mat n m a) -> (mat n m a) -> (mat n m a)
  (*) : (mat n m a) -> (mat m o a) -> (mat n o a)