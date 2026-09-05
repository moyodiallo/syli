Typing recursive functions in Syli
  $ cat >test_file.sy <<EOF
  > primitive (==) : i64 -> i64 -> bool = "eq"
  > primitive (*)  : i64 -> i64 -> i64 = "mul"
  > primitive (-)  : i64 -> i64 -> i64 = "sub"
  > let rec factorial n =
  >   if n == 0 then
  >     1
  >   else
  >     n * factorial (n - 1)
  > end
  > EOF
  $ cat test_file.sy
  primitive (==) : i64 -> i64 -> bool = "eq"
  primitive (*)  : i64 -> i64 -> i64 = "mul"
  primitive (-)  : i64 -> i64 -> i64 = "sub"
  let rec factorial n =
    if n == 0 then
      1
    else
      n * factorial (n - 1)
  end
  $ dune exec sylic typing test_file.sy
  Typed test_file.sy successfully: module Test_file with 4 top-level typed items
  Type Environment:
  {
    * : i64 -> i64 -> i64
    - : i64 -> i64 -> i64
    == : i64 -> i64 -> bool
    factorial : i64 -> i64
  }
