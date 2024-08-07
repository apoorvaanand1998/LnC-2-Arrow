# Open questions

## Exercise 4

   Happy prefers left-recursive grammars because it is more efficient at parsing it.
   This is because they result in a constant stack-space parser, whereas right-recursive
   rules require stack space proportional to the length of the list being parsed.

   Although parsing left-recursive grammars (in Happy) makes a sequence come out reversed.

   This situation is the opposite with parser combinators where we want to remove
   left-recursion because it may lead to an infinite loop.
   
## Exercise 10

   During every recursive call, we hope that the sequence of commands before (potentially) the next recursive call, puts the Arrow in a State such that we don't keep adding the Commands of a particular Rule over and over again. 

   The commands after a recursive call are added to the stack over and over again, but they are not executed until we are able to leave the recursion. So if the recursive call is in the middle of a sequence of commands, the stack keeps growing by the number of elements after the recursive call. Thus, if the recursive call is at the end, the stack size remains constant (Reminiscent of tail-call recursion :))

   The edge-case to watch out for is if a rule calls itself recursively at the head of the sequence of commands. In this case, we enter an infinite loop because the command keeps being added to the top of the stack, and the commands after it too, but with no way for us to leave this sequence of commands! This keeps growing our stack, until we run out of stack space which causes us to crash/error out.

   For example,

      Case 1 - In the end

      start -> take, take, take, start
      
      Stack1 -> [take, take, take]
      Stack2 -> [take, take, take] 
      Stack3 -> ... (and this keeps continuing)

      Case 2 - In the middle 

      start -> take, take, start, go, go

      Stack1 -> [mark, mark] -- some previous state
      Stack2 -> [take, take, start, go, go]
      Stack3 -> [take, take, start, go, go, go, go]
      Stack4 -> [take, take, start, go, go, go, go, go, go]
      (...and so on, until it reaches a state where start's commands are not added and then the "go"s are executed)

      Case 3 - In the front

      someCommand -> someCommand, take, go

      Stack1 -> [someCommand, take, go]
      Stack2 -> [someCommand, take, go, take, go]
      Stack3 -> [someCommand, take, go, take, go, take, go]
      (...keeps going like this infinitely)