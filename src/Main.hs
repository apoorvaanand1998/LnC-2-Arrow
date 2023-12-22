-- I copied the Main module into src/ because cabal repl
-- don't know if there's another way to test things inside it better?
module Main where

import Algebra
import Model
import Interpreter
import Lexer
import Parser
import qualified Data.Map as M

-- Exercise 11

data ModCon = Reg Contents | Arr Heading deriving (Eq, Ord, Show)
type ModSpace = M.Map Pos ModCon

modSpace :: ArrowState -> ModSpace
modSpace (ArrowState sp p h _) = M.adjustWithKey (\_ _ -> Arr h) p allReg
  where
    allReg = M.map Reg sp

interactive :: Environment -> ArrowState -> IO ()
interactive e i@(ArrowState _ pi _ _) = do
  let ms = modSpace i
  putStrLn (coolPrinter ms pi)
  putStrLn "Press anything to continue (ctrl+c to end)"
  _ <- getLine
  let s = step e i
  case s of
    Done sp p h -> putStrLn (coolPrinter (modSpace (ArrowState sp p h [])) p ++ "\n Yahoo, DONE!")
    Ok as       -> interactive e as
    Fail s      -> putStrLn s

coolPrinter :: ModSpace -> Pos -> String
coolPrinter ms p =
  let
    fm = M.findMax ms
    nr = fst (fst fm)
    nc = snd (fst fm)
    nm = M.fromList modContentsTable
    fd k = M.findWithDefault '.' k nm
    rc = show (nr, nc) ++ "\n"
  in
    "Map size - " ++ rc ++
    "Current position - " ++ show p ++ "\n" ++
    foldr (\((r, c), ct) s -> if c == nc then fd ct:'\n':s else fd ct:s) "" (M.toList ms)

modContentsTable :: [ (ModCon, Char)]
modContentsTable =  [ (Reg Empty   , '.'  )
                    , (Reg Lambda  , '\\' )
                    , (Reg Debris  , '%'  )
                    , (Reg Asteroid, 'O'  )
                    , (Reg Boundary, '#'  )
                    , (Arr North   , '↟'  )
                    , (Arr South   , '↡'  )
                    , (Arr West    , '↞' )
                    , (Arr East    , '↠' ) ]

batch :: Environment -> ArrowState -> (Space, Pos, Heading)
batch e as = if fst (isDone oneStepCloser)
             then snd (isDone oneStepCloser)
             else batch e as
  where
    isDone (Done s p h) = (True, (s, p, h))
    isDone (Ok _      ) = (False, undefined)
    isDone (Fail s    ) = error s

    oneStepCloser = step e as

main :: IO ()
main = do
  putStrLn "Enter name of .space file"
  putStrLn "For example - \"AddInput.space\""
  sf <- getLine
  putStrLn "Enter name of .arrow file"
  putStrLn "For example - \"Add.arrow\""
  af <- getLine
  let sfp = "../examples/" ++ sf
  let afp = "../examples/" ++ af
  afps <- readFile afp
  s <- testSpace sfp
  let e = toEnvironment afps
  let cs = concatMap snd $ testParser afps
  putStrLn "Enter start position - (Pos, Pos)"
  putStrLn "For example - (0, 0)"
  sPos <- getLine
  let pos = read sPos :: (Int, Int)
  putStrLn "Enter the direction Arrow is Heading - North, South, West, East"
  sh <- getLine
  let h = read sh :: Heading
  putStrLn "Pick mode - 1. Batch 2. Interactive"
  mode <- getLine
  if mode == "1"
  then print (batch e (ArrowState s pos h cs))
  else interactive e (ArrowState s pos h cs)

  -- test
testInteractive :: FilePath -> IO ()
testInteractive f = do
  sp <- testSpace f
  let p = testParser stringifiedAdd
  let cs = concatMap snd p
  interactive (toEnvironment stringifiedAdd) (ArrowState sp (3, 5) North cs)