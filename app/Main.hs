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
interactive e i = do
  let ms = modSpace i
  putStrLn (coolPrinter ms)
  putStrLn "Press anything to continue"
  _ <- getLine
  let s = step e i
  case s of
    Done sp p h -> putStrLn (coolPrinter (modSpace (ArrowState sp p h [])))
    Ok as       -> interactive e as
    Fail s      -> putStrLn s

coolPrinter :: ModSpace -> String
coolPrinter ms = 
  let
    fm = M.findMax ms
    nr = fst (fst fm)
    nc = snd (fst fm)
    nm = M.fromList modContentsTable
    fd k = M.findWithDefault '.' k nm
    rc = show (nr, nc) ++ "\n"
  in
    rc ++ foldr (\((r, c), ct) s -> if c == nc then fd ct:'\n':s else fd ct:s) "" (M.toList ms)

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
batch = undefined

-- This function is just here to play around with and test your lexer/parser.
-- When implementing exercise 11, delete this comment and this function,
-- and write a new main function.
main :: IO ()
main = do
  chars <- readFile "examples/Add.arrow"
  putStrLn "Input program:"
  putStrLn ""
  putStrLn chars
  putStrLn ""
  let tokens = alexScanTokens chars
  putStrLn "Tokens:"
  putStrLn ""
  print tokens
  let arr = parser tokens
  putStrLn "Parsed program:"
  putStrLn ""
  print arr

  -- test
testInteractive :: FilePath -> IO ()
testInteractive f = do
  sp <- testSpace f
  let p = testParser stringifiedAdd
  let cs = concatMap snd p
  interactive (toEnvironment stringifiedAdd) (ArrowState sp (3, 5) North cs)