
{-# language
  RankNTypes, GADTs, TypeInType, LambdaCase, TypeApplications,
  TypeOperators, StandaloneDeriving, TupleSections, EmptyCase,
  ScopedTypeVariables, TypeFamilies, ConstraintKinds,
  FlexibleContexts, MultiParamTypeClasses, AllowAmbiguousTypes,
  FlexibleInstances, DeriveFunctor, UndecidableInstances,
  NoMonomorphismRestriction #-}

import Data.Kind
import Data.Type.Bool
import Control.Monad
import Control.Arrow
import Data.Word

-- Examples
--------------------------------------------------------------------------------

-- polymorphic state
test1 = run $ runState 0 $
  modify (+100)

-- multiple monomorphic state
test3 = run $ runState 'a' $ runState True $ do
  c <- get
  put (c == 'a')

-- multiple & polymorphic state
test2 = run $ runState [0..10] $ runState (0 :: Int) $ do
  xs <- get
  put $ length xs

-- This works because we first traverse monomorphic first tuple components
test4 = run $ runState ('a', 0) $ runState (True, 0) $
  put (False, 0)

-- This fails for the same reason
test5 = run $ runState (0, 'a') $ runState (0, True) $ do
  -- put (0, False) -- error
  pure ()

-- Multiple writer with type applications
test6 = run $ runWriter @String $ runWriter @[Int] $ do
  tell "foo"
  tell @[Int] [0..10]

-- Multiple state with type applications
test7 = run $ runState @Int 0 $ runState @Word 0 $ do
  modify @Int (+100)
  modify @Word (+100)

-- Effect shadowing disallowed
test8 = run $ runWriter @String $ runWriter @String $
  -- tell "foo" -- error
  pure ()


-- Untyped preorder traversal of types
--------------------------------------------------------------------------------

data Entry = App | forall a. Con a

type family (xs :: [a]) ++ (ys :: [a]) :: [a] where
  '[]       ++ ys = ys
  (x ': xs) ++ ys = x ': (xs ++ ys)

type family Preord (x :: a) :: [Entry] where
  Preord (f x) = App ': (Preord f ++ Preord x)
  Preord x     = '[ Con x]

-- Find index of unique occurrence, become stuck if occurrence is non-unique or
-- there's no occurrence
--------------------------------------------------------------------------------

data Nat = Z | S Nat

type family (x :: a) == (y :: b) :: Bool where
  x == x = True
  _ == _ = False

type family PreordList (xs :: [a]) (i :: Nat) :: [(Nat, [Entry])] where
  PreordList '[]       _ = '[]
  PreordList (a ': as) i = '(i, Preord a) ': PreordList as (S i)

type family Narrow (e :: Entry) (xs :: [(Nat, [Entry])]) :: [(Nat, [Entry])] where
  Narrow _ '[]                     = '[]
  Narrow e ('(i, e' ': es) ': ess) = If (e == e') '[ '(i, es)] '[] ++ Narrow e ess

type family Find_ (es :: [Entry]) (ess :: [(Nat, [Entry])]) :: Nat where
  Find_ _        '[ '(i, _)] = i
  Find_ (e ': es) ess        = Find_ es (Narrow e ess)

type Find x ys = Find_ (Preord x) (PreordList ys Z)


-- Open functor sums
--------------------------------------------------------------------------------

data NS :: [* -> *] -> * -> * where
  Here  :: f x -> NS (f ': fs) x
  There :: NS fs x -> NS (f ': fs) x

instance Functor (NS '[]) where
  fmap _ = \case {}

instance (Functor f, Functor (NS fs)) => Functor (NS (f ': fs)) where
  fmap f (Here fx)  = Here  (fmap f fx)
  fmap f (There ns) = There (fmap f ns)

class Elem' (n :: Nat) (f :: * -> *) (fs :: [* -> *]) where
  inj' :: forall x. f x -> NS fs x
  prj' :: forall x. NS fs x -> Maybe (f x)

instance (gs ~ (f ': gs')) => Elem' Z f gs where
  inj'           = Here
  prj' (Here fx) = Just fx
  prj' _         = Nothing

instance (Elem' n f gs', (gs ~ (g ': gs'))) => Elem' (S n) f gs where
  inj'            = There . inj' @n
  prj' (Here _)   = Nothing
  prj' (There ns) = prj' @n ns

type family Elems_ fs gs :: Constraint where
  Elems_ '[]       gs = ()
  Elems_ (f ': fs) gs = (Elem' (Find f gs) f gs, Elems_ fs gs)

type Elem  f  fs = (Functor (NS fs), Elem' (Find f fs) f fs)
type Elems fs gs = (Functor (NS gs), Elems_ fs gs)

inj :: forall fs f x. Elem f fs => f x -> NS fs x
inj = inj' @(Find f fs)

prj :: forall f x fs. Elem f fs => NS fs x -> Maybe (f x)
prj = prj' @(Find f fs)

-- Eff monad
--------------------------------------------------------------------------------

data Eff fs a = Pure a | Free (NS fs (Eff fs a))

deriving instance (Show a, Show (NS fs (Eff fs a))) => Show (Eff fs a)
deriving instance (Eq a, Eq (NS fs (Eff fs a))) => Eq (Eff fs a)
deriving instance (Functor (NS fs)) => Functor (Eff fs)

instance Functor (NS fs) => Applicative (Eff fs) where
  pure          = Pure
  Pure f  <*> b = f <$> b
  Free fs <*> b = Free ((<*> b) <$> fs)

instance Functor (NS fs) => Monad (Eff fs) where
  return = Pure
  Pure a  >>= f = f a
  Free fs >>= f = Free ((>>= f) <$> fs)

run :: Eff '[] a -> a
run (Pure a) = a

liftEff :: (Functor f, Elem f fs) => f a -> Eff fs a
liftEff fa = Free (inj (Pure <$> fa))

handleRelay ::
     Functor (NS fs)
  => (a -> Eff fs b)
  -> (f (Eff (f ': fs) a) -> Eff fs b)
  -> Eff (f ': fs) a -> Eff fs b
handleRelay p f = go where
  go (Pure x)          = p x
  go (Free (Here fx))  = f fx
  go (Free (There ns)) = Free (go <$> ns)

interpose ::
     Elem f fs
  => (a -> Eff fs b)
  -> (f (Eff fs a) -> Eff fs b)
  -> Eff fs a -> Eff fs b
interpose p f = go where
  go (Pure x)  = p x
  go (Free ns) = maybe (Free (go <$> ns)) f (prj ns)

-- State
--------------------------------------------------------------------------------

data State s k = Put s k | Get (s -> k) deriving Functor

runState :: forall s fs a. Functor (NS fs) => s -> Eff (State s ': fs) a -> Eff fs (a, s)
runState s = handleRelay (Pure . (,s)) $ \case
  Put s' k -> runState s' k
  Get k    -> runState s (k s)

get :: forall s fs. Elem (State s) fs => Eff fs s
get = liftEff (Get id)

put :: forall s fs. Elem (State s) fs => s -> Eff fs ()
put s = liftEff (Put s ())

modify :: forall s fs. Elem (State s) fs => (s -> s) -> Eff fs ()
modify f = put =<< f <$> get

-- Reader
--------------------------------------------------------------------------------

newtype Reader r k = Ask (r -> k) deriving Functor

runReader :: forall r fs a. Functor (NS fs) => r -> Eff (Reader r ': fs) a -> Eff fs a
runReader r = handleRelay Pure (\(Ask k) -> runReader r (k r))

ask :: forall r fs. Elem (Reader r) fs => Eff fs r
ask = liftEff (Ask id)

local :: forall r fs a. Elem (Reader r) fs => (r -> r) -> Eff fs a -> Eff fs a
local f e = do
  r <- f <$> ask
  interpose Pure (\(Ask k) -> k r) e

-- Exception
--------------------------------------------------------------------------------

newtype Exc e k = Throw e deriving Functor

throw :: forall e fs a. Elem (Exc e) fs => e -> Eff fs a
throw e = liftEff (Throw e)

runExc :: forall e fs a. Functor (NS fs) => Eff (Exc e ': fs) a -> Eff fs (Either e a)
runExc = handleRelay (Pure . Right) (\(Throw e) -> Pure (Left e))

catch :: Elem (Exc e) fs => Eff fs a -> (e -> Eff fs a) -> Eff fs a
catch eff h = interpose Pure (\(Throw e) -> h e) eff

-- Lift
--------------------------------------------------------------------------------

data Lift m k = forall a. Lift (m a) (a -> k)
deriving instance Functor (Lift m)

lift :: forall m fs a. Elem (Lift m) fs => m a -> Eff fs a
lift ma = liftEff (Lift ma id)

runLift :: forall m a. Monad m => Eff '[Lift m] a -> m a
runLift (Pure a)                  = pure a
runLift (Free (Here (Lift ma k))) = runLift . k =<< ma

-- Writer
--------------------------------------------------------------------------------

data Writer m k = Tell m k deriving (Functor)

tell :: (Monoid m, Elem (Writer m) fs) => m -> Eff fs ()
tell m = liftEff (Tell m ())

runWriter :: forall m fs a.
  (Monoid m, Functor (NS fs)) => Eff (Writer m ': fs) a -> Eff fs (a, m)
runWriter = handleRelay
  (Pure . (,mempty))
  (\(Tell m k) -> second (`mappend` m) <$> runWriter k)


