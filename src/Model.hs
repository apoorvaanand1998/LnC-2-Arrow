module Model where


-- Exercise 1
data Token = Arrow | Dot | Comma
           | Go | Take | Mark | TNothing | Turn
           | Case | Of | End 
           | TLeft | TRight | Front 
           | Semicolon
           | EmptyT | LambdaT | DebrisT | AsteroidT | BoundaryT | UnderscoreT
           | Ident { getIdent :: String }
    deriving Show


-- Exercise 2
type Program = [Rule]

type Rule = (String, [Cmd])

data Cmd = GoC | TakeC | MarkC | NothingC
         | TurnC Dir
         | CaseC Dir [Alt]
         | IdentC String
    deriving (Show, Eq)

data Dir = LeftD | RightD | FrontD deriving (Show, Eq)

type Alt = (Pat, [Cmd])

data Pat = EmptyP | LambdaP | DebrisP | AsteroidP | BoundaryP | AllP deriving (Show, Eq, Ord)

-- test

stringifiedAdd :: String
stringifiedAdd = "start       -> turn right, go, turn left, firstArg.\r\n\r\nturnAround  -> turn right, turn right.\r\n\r\nreturn      -> case front of\r\n                 Boundary  ->  nothing;\r\n                 Asteroid         ->  go, return\r\n               end.\r\n\r\nfirstArg    -> case left of\r\n                 Lambda  ->  go, firstArg, mark, go;\r\n                 _       ->  turnAround, return, turn left, go, go, turn left,\r\n                             secondArg\r\n               end.\r\n\r\nsecondArg   -> case left of\r\n                 Lambda  ->  go, secondArg, mark, go;\r\n                 _       ->  turnAround, return, turn left, go, turn left\r\n               end.\r\n\r\n"

strinifiedFind :: String
strinifiedFind = "start  ->  case left of\r\n             Asteroid -> goOn;\r\n             Boundary -> goOn;\r\n             Lambda   -> turn left, go, take;\r\n             _        -> turn left, go, start\r\n           end.\r\n\r\ngoOn   ->  case front of\r\n             Asteroid -> turn right, goOn;\r\n             Boundary -> turn right, goOn;\r\n             Lambda   -> go, take;\r\n             _        -> go, start\r\n           end.\r\n"

stringifiedRemove :: String
stringifiedRemove = "\r\nstart -> take,\r\n         case front of\r\n           Debris -> go, start, turn right, turn right,\r\n                     go, turn right, turn right;\r\n           _      -> nothing\r\n         end,\r\n         turn right,\r\n         s2.\r\n\r\ns2    -> take,\r\n         case front of\r\n           Debris -> go, start, turn right, turn right,\r\n                     go, turn right, turn right;\r\n           _      -> nothing\r\n         end,\r\n         turn right,\r\n         s3.\r\n\r\n\r\ns3    -> take,\r\n         case front of\r\n           Debris -> go, start, turn right, turn right,\r\n                     go, turn right, turn right;\r\n           _      -> nothing\r\n         end,\r\n         turn right,\r\n         s4.\r\n\r\ns4    -> take,\r\n         case front of\r\n           Debris -> go, start, turn right, turn right,\r\n                     go, turn right, turn right;\r\n           _      -> nothing\r\n         end,\r\n         turn right.\r\n\r\n"