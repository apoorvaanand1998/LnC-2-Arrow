module Interpreter where

import ParseLib.Abstract
import Prelude hiding ((<$), ($>), (<*), (*>), sequence)

import Data.Map (Map, fromList, toList, findMax, findWithDefault)
import qualified Data.Map as L

import Data.Char (isSpace)
import Control.Monad (replicateM)

import Lexer
import Parser
import Model
import Algebra


data Contents  =  Empty | Lambda | Debris | Asteroid | Boundary deriving (Eq, Ord)

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
  in
     foldr (\((r, c), ct) s -> if c == nc then fd ct:'\n':s else fd ct:s) "" (toList s)


-- These three should be defined by you
type Ident = ()
type Commands = ()
type Heading = ()

type Environment = Map Ident Commands

type Stack       =  Commands
data ArrowState  =  ArrowState Space Pos Heading Stack

data Step =  Done  Space Pos Heading
          |  Ok    ArrowState
          |  Fail  String

-- | Exercise 8
toEnvironment :: String -> Environment
toEnvironment = undefined

-- | Exercise 9
step :: Environment -> ArrowState -> Step
step = undefined

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
  print $ printSpace s