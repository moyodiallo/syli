let raw_line_content filename =
  try
    let ic = open_in filename in
    let content = really_input_string ic (in_channel_length ic) in
    close_in ic;
    Some content
  with _ -> None

let line_col_of_offset content offset =
  let rec loop line line_start i =
    if i >= offset then (line, offset - line_start)
    else if i >= String.length content then (line, offset - line_start)
    else if content.[i] = '\n' then loop (line + 1) (i + 1) (i + 1)
    else loop line line_start (i + 1)
  in
  loop 1 0 0

let split_line content line_num =
  let rec split_to n i =
    if n = 1 then i
    else if i >= String.length content then i
    else if content.[i] = '\n' then split_to (n - 1) (i + 1)
    else split_to n (i + 1)
  in
  let rec take_to_nl i =
    if i >= String.length content then i
    else if content.[i] = '\n' then i
    else take_to_nl (i + 1)
  in
  let start = split_to line_num 0 in
  let stop = take_to_nl start in
  String.sub content start (stop - start)

let show_error ~kind ~filename ~start_pos ~end_pos ~msg =
  let skipped = start_pos = 0 && end_pos = 0 in
  match (skipped, raw_line_content filename) with
  | true, _ -> Printf.eprintf "%s error: %s\n" kind msg
  | false, None -> Printf.eprintf "%s error: %s\n" kind msg
  | false, Some content ->
      let line, col = line_col_of_offset content start_pos in
      let line_content = split_line content line in
      Printf.eprintf "%s error in %s at line %d, column %d\n" kind filename line
        col;
      Printf.eprintf "\n";
      Printf.eprintf "  %d | %s\n" line line_content;
      let spaces =
        String.make (col + String.length (string_of_int line) + 3) ' '
      in
      let span = end_pos - start_pos in
      let max_carets = String.length line_content - col in
      let caret_len = max 1 (min span max_carets) in
      let carets = String.make caret_len '^' in
      Printf.eprintf "  %s%s\n" spaces carets;
      Printf.eprintf "\n";
      Printf.eprintf "%s\n" msg
