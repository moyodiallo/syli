
Pattern match
  $ cat >parse0.src <<EOF
  > let x = 10
  > let _ = 
  >   match x with
  >   | 10 -> print_int(1)
  >   | _ -> print_int(0)
  > let _ = print_int(5)
  > EOF
  $ cat parse0.src
  let x = 10
  let _ = 
    match x with
    | 10 -> print_int(1)
    | _ -> print_int(0)
  let _ = print_int(5)
  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let x = 10
  let _ = match x {
    | 10 -> print_int 1
    | _ -> print_int 0
  }
  let _ = print_int 5

Nested pattern match
  $ cat >parse0.src <<EOF
  > let x = 10
  > let _ = 
  >   match x with
  >   | 10 ->
  >     match y with
  >     | 20 -> print_int 20
  >     | _  -> print_int 0
  >   | _ -> print_int(0)
  > let _ = print_int(5)
  > EOF
  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let x = 10
  let _ = match x {
    | 10 -> match y {
      | 20 -> print_int 20
      | _ -> print_int 0
    }
    | _ -> print_int 0
  }
  let _ = print_int 5

  $ cat >parse0.src <<EOF
  > let rec factorial n =
  >   if n == 0 then
  >     1
  >   else
  >     n * factorial (n - 1)
  > end
  > EOF
  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let factorial = lambda(n) {
    if (==) n 0 {
      1
    } else {
      (*) n (factorial ((-) n 1))
    }
  }

Operator definition
  $ cat >operators.sy <<EOF
  > let (==) f x =  f x
  > let _ = print_int 8
  > EOF
  $ dune exec sylic -- parse operators.sy
  Parsed operators.sy
  let (==) = lambda(f, x) {
    f x
  }
  let _ = print_int 8

Operator application
  $ cat >operators.sy <<EOF
  > let _ = (==) (fun x -> x) 3
  > EOF
  $ dune exec sylic -- parse operators.sy
  Parsed operators.sy
  let _ = (==) lambda(x) {
    x
  } 3
