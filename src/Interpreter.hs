module Interpreter where

import ParseLib.Abstract
import Prelude hiding ((<$), ($>), (<*), (*>), sequence, lookup)

import Data.Map (Map, lookup, fromList, toList, findMax, findWithDefault, adjust, (!))
import qualified Data.Map as L

import Data.Char (isSpace)
import Control.Monad (replicateM)

import Lexer
import Parser
import Model
import Algebra


data Contents  =  Empty | Lambda | Debris | Asteroid | Boundary deriving (Eq, Ord, Show)

type Size      =  Int
type Pos       =  (Int, Int)
type Space     =  Map Pos Contents



-- | Parses a space file, such as the ones in the examples folder.
parseSpace :: Parser Char Space
parseSpace = do
    (mr, mc) <- parenthesised ((,) <$> natural <* symbol ',' <*> natural)
                <* spaces
    -- read |mr + 1| rows of |mc + 1| characters
    css      <- replicateM (mr + 1) (replicateM (mc + 1) contents)
    -- convert from a list of lists to a finite map representation
    return $ L.fromList $ concat $
            zipWith (\r cs ->
              zipWith (\c d -> ((r, c), d)) [0..] cs) [0..] css
  where
    spaces :: Parser Char String
    spaces = greedy (satisfy isSpace)

    contents :: Parser Char Contents
    contents = choice (Prelude.map (\(f,c) -> f <$ symbol c) contentsTable)
      <* spaces


-- | Conversion table
contentsTable :: [ (Contents, Char)]
contentsTable =  [ (Empty   , '.' )
                 , (Lambda  , '\\')
                 , (Debris  , '%' )
                 , (Asteroid, 'O' )
                 , (Boundary, '#' )]


-- Exercise 7
printSpace :: Space -> String
printSpace s =
  let
    fm = findMax s
    nr = fst (fst fm)
    nc = snd (fst fm)
    nm = fromList contentsTable
    fd k = findWithDefault '.' k nm
    rc = show (nr, nc) ++ "\n"
  in
    rc ++ foldr (\((r, c), ct) s -> if c == nc then fd ct:'\n':s else fd ct:s) "" (toList s)


-- These three should be defined by you
type Ident = String
type Commands = [Cmd]
data Heading = North | South | West | East deriving (Eq, Ord, Show, Read)

type Environment = Map Ident Commands

type Stack       =  Commands
data ArrowState  =
  ArrowState
    { space   :: Space,
      posR    :: Pos,
      heading :: Heading,
      stack   :: Stack }

data Step =  Done  Space Pos Heading
          |  Ok    ArrowState
          |  Fail  String

-- | Exercise 8
toEnvironment :: String -> Environment
toEnvironment s = if checkProgram p
                  then m
                  else error "Yo, your program sux" -- Throwing an error as recommended by David
                  -- would be cool if we could tell specifically which prop failed, but not required by spec soooo
  where
    p = parser $ alexScanTokens s
    m = fromList p

-- | Exercise 9
step :: Environment -> ArrowState -> Step
step e as@(ArrowState sp p h s) = case s of
  []     -> Done sp p h
  (c:cs) -> case c of
    GoC -> if goOk (content (fwd p h) sp)
           then Ok (ArrowState sp (fwd p h) h cs)
           else Ok as
    TakeC -> if content p sp == Lambda || content p sp == Debris
             then Ok (ArrowState (takeSp p sp) p h cs)
             else Ok as
    MarkC -> Ok (ArrowState (markSp p sp) p h cs)
    NothingC -> Ok (ArrowState sp p h cs)
    TurnC d -> Ok (ArrowState sp p (turnH d h) cs)
    CaseC d as -> if null (wCmds d as)
                  then Fail "Case failed : Pattern Match"
                  else resCase cs (wCmds d as)
    IdentC is -> maybe (Fail "Lookup Failed : Unknown Rule") (resCase cs) (lookup is e)
  where
    wCmds d = whichCmds (sensor d p h sp)
    resCase cs x = Ok (ArrowState sp p h (x++cs))

    fwd :: Pos -> Heading -> Pos
    fwd (x, y) North = (x-1, y)
    fwd (x, y) South = (x+1, y)
    fwd (x, y) West  = (x, y-1)
    fwd (x, y) East  = (x, y+1)

    content :: Pos -> Space -> Contents
    content = findWithDefault Boundary

    goOk :: Contents -> Bool
    goOk Empty  = True
    goOk Lambda = True
    goOk Debris = True
    goOk _      = False

    takeSp :: Pos -> Space -> Space
    takeSp = adjust (const Empty)

    markSp :: Pos -> Space -> Space
    markSp = adjust (const Lambda)

    turnH :: Dir -> Heading -> Heading
    turnH FrontD h = h
    turnH LeftD  h = case h of
      North -> West
      West  -> South
      South -> East
      East  -> North
    turnH RightD h = case h of
      North -> East
      East  -> South
      South -> West
      West  -> North
    -- i guess you could also do these by putting the headings in a list
    -- and doing some modulo magic

    sensor :: Dir -> Pos -> Heading -> Space -> Contents
    sensor d p h = content (fwd p (turnH d h))

    whichCmds :: Contents -> [Alt] -> Commands
    whichCmds c []     = []
    whichCmds c (a:as) = if patCon (fst a) c
                         then snd a
                         else whichCmds c as

    patCon :: Pat -> Contents -> Bool
    patCon EmptyP    Empty    = True
    patCon LambdaP   Lambda   = True
    patCon DebrisP   Debris   = True
    patCon AsteroidP Asteroid = True
    patCon BoundaryP Boundary = True
    patCon AllP      _        = True
    patCon _         _        = False

-- test
testSpace :: FilePath -> IO Space
testSpace f = do
  s <- readFile f
  let space = parse parseSpace s
  if null space
  then return L.empty
  else return (fst (head space))

testPrintSpace :: FilePath -> IO ()
testPrintSpace f = do
  s <- testSpace f
  putStrLn $ printSpace s