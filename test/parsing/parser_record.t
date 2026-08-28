
  $ cat >parse0.src <<EOF
  > let add () =
  >  let record = { name = "test"; value = 5 }
  >  let n = record.value
  >  record.value := 10
  >  print_int (5 + 4) (5)
  >  print_int 5 5
  >  print_int 5 5 4
  > end
  > EOF
  $ cat parse0.src
  let add () =
   let record = { name = "test"; value = 5 }
   let n = record.value
   record.value := 10
   print_int (5 + 4) (5)
   print_int 5 5
   print_int 5 5 4
  end

  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let add = lambda(()) {
    {
      let record = { name = "test"; value = 5 };
      let n = record.value;
      record.value := 10;
      print_int ((+) 5 4) 5;
      print_int 5 5;
      print_int 5 5 4
    }
  }

  $ cat >parse0.src <<EOF
  > let add a =
  >   let record = { 
  >        name = "test"; value = 5 
  >   }
  >   let n = record.value
  > end
  > let _ = print_int (add 10)
  > EOF
  $ cat parse0.src
  let add a =
    let record = { 
         name = "test"; value = 5 
    }
    let n = record.value
  end
  let _ = print_int (add 10)

  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let add = lambda(a) {
    {
      let record = { name = "test"; value = 5 };
      let n = record.value
    }
  }
  let _ = print_int (add 10)


  $ cat >parse0.src <<EOF
  > let add a =
  >   let record = { 
  >        name = "test"; value = 5 
  >   }
  >   let n = record.value
  > end
  > let _ = print_int (add 10)
  > EOF
  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let add = lambda(a) {
    {
      let record = { name = "test"; value = 5 };
      let n = record.value
    }
  }
  let _ = print_int (add 10)


  $ cat >parse0.src <<EOF
  > let add a =
  >   let record = { 
  >        name = "test"; value = 5 
  >     }
  >   let n = record.value
  > end
  > let _ = print_int (add 10)
  > EOF
  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let add = lambda(a) {
    {
      let record = { name = "test"; value = 5 };
      let n = record.value
    }
  }
  let _ = print_int (add 10)

  $ cat >parse0.src <<EOF
  > let add a =
  >   let record = 
  >   { 
  >        name = "test"; value = 5 
  >   }
  >   let n = record.value
  > end
  > let _ = print_int (add 10)
  > EOF
  $ dune exec sylic parse parse0.src
  Parsed parse0.src
  let add = lambda(a) {
    {
      let record = { name = "test"; value = 5 };
      let n = record.value
    }
  }
  let _ = print_int (add 10)
