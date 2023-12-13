{
module Lexer where

import Model
}

%wrapper "basic"

$letters = [a-zA-Z]
$digits  = [0-9]
$sym     = [\+ \-]
@names   = ($letters | $digits | $sym )+

tokens :-
  $white+           ;
  \->               { const Arrow }
  \.                { const Dot }
  \,                { const Comma }
  go                { const Go }
  take              { const Take }
  mark              { const Mark }
  nothing           { const TNothing }
  turn              { const Turn }
  case              { const Case }
  of                { const Of }
  end               { const End }
  left              { const TLeft }
  right             { const TRight }
  front             { const Front }
  \;                { const Semicolon }
  Empty             { const EmptyT }
  Lambda            { const LambdaT }
  Debris            { const DebrisT }
  Asteroid          { const AsteroidT }
  Boundary          { const BoundaryT }
  \_                { const UnderscoreT }
  @names            { \s -> Ident s }