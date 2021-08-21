# comments, but mutable

project for https://github.com/langjam/jam0001

## ideas

* comments are first-class
  + you can bind comments to variable, pass them around, return them, etc.
  + some operations can be performed on comments (e.g. `+/` appends two comments: `/* hello */ +/ /* world */ = /* hello  world */`)
* comments are *mutable*
* every time you mutate a comment, the program's source code is mutated
* mutation on its own wouldn't be super interested, so you can use the `reload` keyword to restart the program once you've changed the comments

### example

```
fun main() {
  let comment = /*hello*/;
  comment +/= /*!*/;
  print(comment);
  reload
}
```
will print out:
```
hello
hello!
hello!!
hello!!!
hello!!!!
hello!!!!!
....
```
and after you kill the program, it should pick up exactly where it left off on the next run!
