  $ cat >parse0.src <<EOF
  > let mut x = 10
  > EOF
  $ cat parse0.src
  let mut x = 10
  $ dune exec sylic alpha parse0.src
  let mut#2 = lambda(x#1) {
    10
  }


  $ cat >parse0.src <<EOF
  > let x = 10
  > EOF
  $ cat parse0.src
  let x = 10
  $ dune exec sylic alpha parse0.src
  let x#1 = 10

  $ cat >parse0.src <<EOF
  > let x = (10, 20)
  > let y = (20, 30, 40)
  > let z = (x, y)
  > EOF
  $ cat parse0.src
  let x = (10, 20)
  let y = (20, 30, 40)
  let z = (x, y)
  $ dune exec sylic alpha parse0.src
  let x#1 = (10, 20)
  let y#2 = (20, 30, 40)
  let z#3 = (x#1, y#2)

  $ cat >parse0.src <<EOF
  > x = 10
  > EOF
  $ cat parse0.src
  x = 10
  $ dune exec sylic alpha parse0.src
  
  Parse error in parse0.src at line 1, column 0
  
    1 | x = 10
         ^^^^^^^^
  
  Unexpected token: 'IDENT(x)'
  
  [1]

  $ cat >parse0.src <<EOF
  > 4 + 5
  > 3 / 0
  > EOF
  $ cat parse0.src
  4 + 5
  3 / 0
  $ dune exec sylic alpha parse0.src
  
  Parse error in parse0.src at line 1, column 0
  
    1 | 4 + 5
         ^^^^^^
  
  Unexpected token: 'INT(4)'
  
  [1]

  $ cat >parse0.src <<EOF
  > let x = 10
  > let _ =
  >   if x == 10 then
  >     print_int(1)
  >   else 
  >     print_int(0)
  > end
  > EOF
  $ cat parse0.src
  let x = 10
  let _ =
    if x == 10 then
      print_int(1)
    else 
      print_int(0)
  end
  $ dune exec sylic alpha parse0.src
  let x#1 = 10
  let _#2 = if (==) x#1 10 {
    print_int 1
  } else {
    print_int 0
  }

  $ cat >parse0.src <<EOF
  > let x =
  >       let x = 10
  >       x + 5
  > end
  > print_int(x)
  > EOF
  $ cat parse0.src
  let x =
        let x = 10
        x + 5
  end
  print_int(x)
  $ dune exec sylic alpha parse0.src
  
  Parse error in parse0.src at line 5, column 0
  
    5 | print_int(x)
         ^^^^^^^^^^^^^^^^
  
  Unexpected token: 'IDENT(print_int)'
  
  [1]

  $ cat >parse0.src <<EOF
  > let x =
  >       let x = 10
  >       x + 5
  > end
  > print_int(x)
  > EOF
  $ cat parse0.src
  let x =
        let x = 10
        x + 5
  end
  print_int(x)
  $ dune exec sylic alpha parse0.src
  
  Parse error in parse0.src at line 5, column 0
  
    5 | print_int(x)
         ^^^^^^^^^^^^^^^^
  
  Unexpected token: 'IDENT(print_int)'
  
  [1]

  $ cat >parse0.src <<EOF
  > let mut x = 0
  > while x < 10
  >   x = x + 1
  > end
  > print_int(x)
  > EOF
  $ cat parse0.src
  let mut x = 0
  while x < 10
    x = x + 1
  end
  print_int(x)
  $ dune exec sylic alpha parse0.src
  
  Parse error in parse0.src at line 2, column 0
  
    2 | while x < 10
         ^^^^^
  
  Unexpected token: 'WHILE'
  
  [1]

  $ cat >parse0.src <<EOF
  > let x =
  >     let x = 10
  >     x + 5
  >     x + 5
  > end
  > EOF
  $ cat parse0.src
  let x =
      let x = 10
      x + 5
      x + 5
  end
  $ dune exec sylic alpha parse0.src
  let x#2 = {
    let x#1 = 10;
    (+) x#1 5;
    (+) x#1 5
  }

  $ cat >parse0.src <<EOF
  > let add (a, b) =
  >   let d = 0
  >   let c = 0
  >   let a = 0
  >   d + c
  >   a + b
  > end
  > EOF
  $ cat parse0.src
  let add (a, b) =
    let d = 0
    let c = 0
    let a = 0
    d + c
    a + b
  end
  $ dune exec sylic alpha parse0.src
  let add#6 = lambda((a#1, b#2)) {
    {
      let d#3 = 0;
      let c#4 = 0;
      let a#5 = 0;
      (+) d#3 c#4;
      (+) a#5 b#2
    }
  }

  $ cat >parse0.src <<EOF
  > let add (a) = a + 5
  > let _ =
  >   print_int (add(10))
  > EOF
  $ cat parse0.src
  let add (a) = a + 5
  let _ =
    print_int (add(10))
  $ dune exec sylic alpha parse0.src
  let add#2 = lambda((a#1)) {
    (+) a#1 5
  }
  let _#3 = print_int (add#2 10)
