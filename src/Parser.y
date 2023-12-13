{
module Parser where

import Model
}

%name parser
%tokentype { Token }
%error { happyError }

%token
  arrow      { Arrow }
  dot        { Dot }
  comma      { Comma }
  go         { Go }
  take       { Take }
  mark       { Mark }
  nothing    { TNothing }
  turn       { Turn }
  case       { Case }
  of         { Of }
  end        { End }
  left       { TLeft }
  right      { TRight }
  front      { Front }
  semicolon  { Semicolon }
  empty      { EmptyT }
  lambda     { LambdaT }
  debris     { DebrisT }
  asteroid   { AsteroidT }
  boundary   { BoundaryT }
  underscore { UnderscoreT }
  ident      { Ident $$ }

%%

Program : Rules { reverse $1 }

Pattern : empty      { EmptyP }
        | lambda     { LambdaP }
        | debris     { DebrisP }
        | asteroid   { AsteroidP }
        | boundary   { BoundaryP }
        | underscore { AllP }

Direction : left     { LeftD }
          | right    { RightD }
          | front    { FrontD }

Alt : Pattern arrow Commands { ($1, reverse $3) }

Alts : Altz        { $1 }   -- right to left-recursion for efficiency
     | {- empty -} { [] }

--splitting it up so (empty ; Alt) isn't allowed

Altz : Alt                { [$1] }
     | Altz semicolon Alt { $3 : $1 }

Command : go                         { GoC }
        | take                       { TakeC }
        | mark                       { MarkC }
        | nothing                    { NothingC }
        | turn Direction             { TurnC $2 }
        | case Direction of Alts end { CaseC $2 (reverse $4) }
        | ident                      { IdentC $1 }

Commands : Commandz    { $1 } -- transformed the grammar to left-recursive
         | {- empty -} { [] } -- this makes it more efficient

Commandz : Command                { [$1] }
         | Commandz comma Command { $3 : $1 } -- so something like (empty , command) cannot be created  

Rule : ident arrow Commands dot { ($1, reverse $3) }

Rules : {- empty -} { [] }
      | Rules Rule  { $2 : $1 }

{

happyError :: [Token] -> a
happyError _ = error "parse error"

}