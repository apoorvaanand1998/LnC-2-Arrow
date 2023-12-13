# Open questions

## Exercise 4

   Happy prefers left-recursive grammars because it is more efficient at parsing it.
   This is because they result in a constant stack-space parser, whereas right-recursive
   rules require stack space proportional to the length of the list being parsed.

   This situation is the opposite with parser combinators where we want to remove
   left-recursion because it may lead to an infinite loop.
   
## Exercise 10
