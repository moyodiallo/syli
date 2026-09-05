  $ cat >parse0.sy <<EOF
  > let x = 10
  > EOF
  $ cat parse0.sy
  let x = 10
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = 10
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = 10

  $ cat >parse0.sy <<EOF
  > let x = 10
  > EOF
  $ cat parse0.sy
  let x = 10
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = 10


  $ cat >parse0.sy <<EOF
  > let x = 10 + 7
  > let y = 20 - 3
  > EOF
  $ cat parse0.sy
  let x = 10 + 7
  let y = 20 - 3
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = (+) 10 7
  let y = (-) 20 3

  $ cat >parse0.sy <<EOF
  > let x = (10, 20)
  > let y = (20, 30, 40)
  > let z = (x, y)
  > EOF
  $ cat parse0.sy
  let x = (10, 20)
  let y = (20, 30, 40)
  let z = (x, y)
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = (10, 20)
  let y = (20, 30, 40)
  let z = (x, y)

  $ cat >parse0.sy <<EOF
  > let x = if true then 10 else 20
  > EOF
  $ cat parse0.sy
  let x = if true then 10 else 20
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = if true {
    10
  } else {
    20
  }

  $ cat >parse0.sy <<EOF
  > let x = 10
  > let _ =
  >   if x == 10 then
  >     print_int(1)
  >   else 
  >     print_int(0)
  >   end
  > EOF
  $ cat parse0.sy
  let x = 10
  let _ =
    if x == 10 then
      print_int(1)
    else 
      print_int(0)
    end
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = 10
  let _ = if (==) x 10 {
    print_int 1
  } else {
    print_int 0
  }

  $ cat >parse0.sy <<EOF
  > let x =
  >       let x = 10
  >       x + 5
  > end
  > EOF
  $ cat parse0.sy
  let x =
        let x = 10
        x + 5
  end
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = {
    let x = 10;
    (+) x 5
  }

  $ cat >parse0.sy <<EOF
  > let x = 0
  > print_int x
  > end
  > EOF
  $ cat parse0.sy
  let x = 0
  print_int x
  end
  $ dune exec sylic parse parse0.sy
  
  Parse error in parse0.sy at line 2, column 0
  
    2 | print_int x
         ^^^^^^^^^^^^^^^^
  
  Unexpected token: 'IDENT(print_int)'
  
  [1]

  $ cat >parse0.sy <<EOF
  > let mut x = 0
  > let _ =
  >   while x < 10 do
  >     x = x + 1
  >   end
  > let _ = print_int(x)
  > EOF
  $ cat parse0.sy
  let mut x = 0
  let _ =
    while x < 10 do
      x = x + 1
    end
  let _ = print_int(x)
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let mut = lambda(x) {
    0
  }
  let _ = while (<) x 10 {
    (=) x ((+) x 1)
  }
  let _ = print_int x

  $ cat >parse0.sy <<EOF
  > let x =
  >     let x = 10
  >     x + 5
  >     x + 5
  > end
  > let _ = print_int(x)
  > EOF
  $ cat parse0.sy
  let x =
      let x = 10
      x + 5
      x + 5
  end
  let _ = print_int(x)
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let x = {
    let x = 10;
    (+) x 5;
    (+) x 5
  }
  let _ = print_int x

  $ cat >parse0.sy <<EOF
  > let add (a) = a + 5
  > EOF
  $ cat parse0.sy
  let add (a) = a + 5
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  let add = lambda((a)) {
    (+) a 5
  }

  $ cat >test_tuple.sy <<EOF
  > let pair x y = (x, y)
  > let triple x y z = (x, y, z)
  > let triple x y z t = (x, y, z, t)
  > let pair_int = pair 1
  > let one_int = pair_int 42
  > let one_str = pair_int "hello"
  > EOF
  $ dune exec sylic parse test_tuple.sy
  Parsed test_tuple.sy
  let pair = lambda(x, y) {
    (x, y)
  }
  let triple = lambda(x, y, z) {
    (x, y, z)
  }
  let triple = lambda(x, y, z, t) {
    (x, y, z, t)
  }
  let pair_int = pair 1
  let one_int = pair_int 42
  let one_str = pair_int "hello"
