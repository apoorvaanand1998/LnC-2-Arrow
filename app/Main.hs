module Main where

import Algebra
import Model
import Interpreter
import Lexer
import Parser
import qualified Data.Map as M

-- Exercise 11

data ModCon = Reg Contents | Arr Heading Contents deriving (Eq, Ord, Show)
type ModSpace = M.Map Pos ModCon

modSpace :: ArrowState -> ModSpace
modSpace (ArrowState sp p h _) = M.adjustWithKey (\_ v -> Arr h (mcon v)) p allReg
  where
    allReg = M.map Reg sp
    
    mcon (Reg c) = c
    mcon (Arr h c) = c

interactive :: Environment -> ArrowState -> IO ()
interactive e i@(ArrowState _ pi _ _) = do
  let ms = modSpace i
  putStrLn (coolPrinter ms pi)
  putStrLn "Enter anything to continue (ctrl+c to end)"
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
    rc = show (nr, nc) ++ "\n"
  in
    "Map size - " ++ rc ++
    "Current position - " ++ show p ++ "\n" ++
    foldr (\((r, c), ct) s -> if c == nc then modContents ct:'\n':s else modContents ct:s) "" (M.toList ms)

modContents :: ModCon -> Char
modContents (Reg Empty)    = '.'
modContents (Reg Lambda)   = '\\'
modContents (Reg Debris)   = '%'
modContents (Reg Asteroid) = 'O'
modContents (Reg Boundary) = '#'
modContents (Arr North _)  = '↟'
modContents (Arr South _)  = '↡'
modContents (Arr West _)   = '↞'
modContents (Arr East _)   = '↠'

batch :: Environment -> ArrowState -> (Space, Pos, Heading)
batch e as = if fst (isDone oneStepCloser)
             then f (snd (isDone oneStepCloser))
             else batch e (g (snd (isDone oneStepCloser)))
  where
    isDone (Done sp p h)               = (True, (sp, p, h, []))
    isDone (Ok (ArrowState sp p h s))  = (False, (sp, p, h, s))
    isDone (Fail s    )                = error s

    oneStepCloser = step e as 
    -- everything u say to me, takes me oneStepCloser to the edge

f :: (a, b, c, d) -> (a, b, c)
f (a, b, c, _) = (a, b, c)
    
g :: (Space, Pos, Heading, Stack) -> ArrowState
g (a, b, c, d) = ArrowState a b c d

g' :: (Space, Pos, Heading) -> ArrowState
g' (a, b, c) = ArrowState a b c []
-- helper functions, not really necessary, especially if 
-- i used record stuff lol

-- this function doesn't work in cabal repl
-- compile the program
-- getLine misbehaves when used in repl
main :: IO ()
main = do
  putStrLn "Enter name of .space file"
  putStrLn "For example - \"AddInput.space\""
  sf <- getLine
  putStrLn "Enter name of .arrow file"
  putStrLn "For example - \"Add.arrow\""
  af <- getLine
  let sfp = "./examples/" ++ sf
  let afp = "./examples/" ++ af
  afps <- readFile afp
  s <- testSpace sfp
  let e = toEnvironment afps
  let cs = concatMap snd $ testParser afps
  putStrLn "Enter start position - (Pos, Pos)"
  putStrLn "For example - (0, 0)"
  pos <- readLn :: IO (Int, Int)
  putStrLn "Enter the direction Arrow is Heading - North, South, West, East"
  h <- readLn :: IO Heading
  putStrLn "Pick mode - 1. Batch 2. Interactive (Ctrl+C to cancel)"
  mode <- getLine
  if mode == "1"
  then let fs = g' (batch e (ArrowState s pos h cs)) 
       in putStrLn (coolPrinter (modSpace fs) (posR fs) ++ "\nYAY DONE\n")
  else interactive e (ArrowState s pos h cs)

  -- test
testInteractive :: FilePath -> IO ()
testInteractive f = do
  sp <- testSpace f
  let p = testParser stringifiedAdd
  let cs = concatMap snd p
  interactive (toEnvironment stringifiedAdd) (ArrowState sp (3, 5) North cs)