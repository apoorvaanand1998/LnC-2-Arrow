# Open questions

## Exercise 4

   Happy prefers left-recursive grammars because it is more efficient at parsing it.
   This is because they result in a constant stack-space parser, whereas right-recursive
   rules require stack space proportional to the length of the list being parsed.

   This situation is the opposite with parser combinators where we want to remove
   left-recursion because it may lead to an infinite loop.
   
## Exercise 10

   Recursive rules do indeed increase the size of the command stack. During every recursive call, we hope that the sequence of commands before (potentially) the next recursive call, puts the Arrow in a State such that we don't keep adding the Commands of a particular Rule over and over again.

   The commands after a recursive call do not end up happening, therefore, if it is at the end, all the commands before it happen and if it is in the middle, all the commands after the recursive call are rendered moot.

   The edge-case to watch out for is if a rule calls itself recursively at the head of the sequence of commands. In this case, we enter an infinite loop because the command keeps being added to the top of the stack, with nothing else being changed.