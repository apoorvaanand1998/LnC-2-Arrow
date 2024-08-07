{-#LANGUAGE TupleSections #-}
module Algebra where

import Model
import Parser
import Lexer
import Data.List (singleton, sort, nub, union, intersect, (\\))
import Data.Bifunctor (second)
import Data.Maybe (catMaybes)
-- Exercise 5

type ProgramAlgebra p r c d a pt =
    ([r] -> p,
    (String, [c]) -> r,       -- RuleAlgebra
    (c, c, c, c,              -- CmdAlgebra
    d -> c,
    d -> [a] -> c,
    String -> c),
    (d, d, d),                -- DirAlgebra
    (pt, [c]) -> a,           -- AltAlgebra
    (pt, pt, pt, pt, pt, pt)) -- PatAlgebra

foldProgram :: ProgramAlgebra p r c d a pt -> Program -> p
foldProgram (program,
            rule,
            (c1, c2, c3, c4, c5, c6, c7),
            (d1, d2, d3),
            alt,
            (pt1, pt2, pt3, pt4, pt5, pt6)) = fp -- i love types
    where
        fp rs = program $ map fr rs

        fr (s, cs) = rule (s, map fc cs)

        fc GoC          = c1
        fc TakeC        = c2
        fc MarkC        = c3
        fc NothingC     = c4
        fc (TurnC d)    = c5 $ fd d
        fc (CaseC d as) = c6 (fd d) (map fa as)
        fc (IdentC s)   = c7 s

        fd LeftD  = d1
        fd RightD = d2
        fd FrontD = d3

        fa (pt, cs) = alt (fpt pt, map fc cs)

        fpt EmptyP    = pt1
        fpt LambdaP   = pt2
        fpt DebrisP   = pt3
        fpt AsteroidP = pt4
        fpt BoundaryP = pt5
        fpt AllP      = pt6

-- Exercise 6

checkProgram :: Program -> Bool
checkProgram p =
    let
        nur = fst $ foldProgram noUndefinedRules p
        sr  = fst $ foldProgram startRule p
        nrt = fst $ foldProgram noRuleTwice p
        pmf = fst $ foldProgram pmFailure p
    in
        nur && sr && nrt && pmf

-- generalized because the first three rules have similar ideas
-- take the Identifier strings from Commands and concatenate them
-- these are the "used" strings
-- take the fst of Rule for named identifiers
-- check rules 
rulesAlgebra :: ([(String, [String])] -> Bool, [(String, [String])] -> [String])
             -> ProgramAlgebra (Bool, [String])
                               (String, [String])
                               [String]
                               String
                               [String]
                               String
rulesAlgebra (checkFun, lBuild) = (\x -> (checkFun x, lBuild x),
                                         second concat,
                                         ([], [], [], [], const [], const concat, singleton),
                                         ([], [], []), -- type matching, can't leave type as unit 
                                         concat . snd,
                                         ([], [], [], [], [], [])) -- just to make the types match

{- we check if the unique, sorted list of named rules
   are the same as the unique, sorted list of used rules -}
noUndefinedRules :: ProgramAlgebra (Bool, [String]) (String, [String]) [String] String [String] String
noUndefinedRules = rulesAlgebra (f1, f2)
    where
        f1 :: [(String, [String])] -> Bool
        f1 x = sort (usNamed x `union` usUsed x) == usNamed x

        f2 :: [(String, [String])] -> [String]
        f2 x = (\\) (usNamed x `union` usUsed x) (usNamed x `intersect` usUsed x)

startRule :: ProgramAlgebra (Bool, [String]) (String, [String]) [String] String [String] String
startRule = rulesAlgebra (f1, f2)
    where
        f1 :: [(String, [String])] -> Bool
        f1 x = "start" `elem` map fst x

        f2 :: [(String, [String])] -> [String]
        f2 x = usNamed x `union` usUsed x

noRuleTwice :: ProgramAlgebra (Bool, [String]) (String, [String]) [String] String [String] String
noRuleTwice = rulesAlgebra (f1, f2)
    where
        f1 :: [(String, [String])] -> Bool
        f1 x = usNamed x == sort (map fst x)

        f2 :: [(String, [String])] -> [String]
        f2 x = usNamed x `union` usUsed x

-- idea behind this Algebra is we only care about taking
-- out the (Dir, [Pat]) from Case
pmFailure :: ProgramAlgebra (Bool, [(Dir, [Pat])])
                             [(Dir, [Pat])]
                             (Maybe (Dir, [Pat]))
                             Dir
                             Pat
                             Pat
pmFailure = (\e -> (all (all (f . snd)) e, concat e),
              \(_, cs) -> catMaybes cs,
              (Nothing, Nothing, Nothing, Nothing,
              const Nothing,
              curry Just,
              const Nothing),
              (LeftD, RightD, FrontD),
              fst,
              (EmptyP, LambdaP, DebrisP, AsteroidP, BoundaryP, AllP))
    where
        f xs = AllP `elem` xs || take 5 (sort xs) == [EmptyP,
                                                      LambdaP,
                                                      DebrisP,
                                                      AsteroidP,
                                                      BoundaryP]


usNamed :: Ord a => [(a, b)] -> [a]
usNamed x = sort $ nub $ map fst x       -- used often so left in scope

usUsed :: (Ord b, Foldable t) => t (a, [b]) -> [b]
usUsed x  = sort $ nub $ concatMap snd x

-- test

testParser :: String -> Program
testParser s = parser $ alexScanTokens s

testP :: FilePath -> IO Program
testP f = do
    s <- readFile f
    return $ testParser s