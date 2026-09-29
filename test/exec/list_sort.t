List type and insertion sort:
  $ cat >test_list_sort.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > foreign syli_print_char : char -> unit = "syli_print_char"
  > primitive (<) : i64 -> i64 -> bool = "lt"
  > type list = Nil | Cons of (i64, list)
  > 
  > let rec insert x xs =
  >   match xs with
  >   | Nil -> Cons (x, Nil)
  >   | Cons (y, ys) ->
  >       if x < y then
  >         Cons (x, Cons (y, ys))
  >       else
  >         Cons (y, insert x ys)
  > 
  > let rec sort xs =
  >   match xs with
  >   | Nil -> Nil
  >   | Cons (x, rest) -> insert x (sort rest)
  > 
  > let rec print_list first xs =
  >   match xs with
  >   | Nil -> ()
  >   | Cons (x, rest) ->
  >       if first then () else syli_print_char ' '
  >       syli_print_i64 x
  >       print_list false rest
  > 
  > let main () =
  >   let xs = Cons (3, Cons (1, Cons (5, Cons (2, Cons (4, Nil)))))
  >   print_list true (sort xs)
  > 
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_list_sort.sy
  $ ./test_list_sort.exe
  1 2 3 4 5
