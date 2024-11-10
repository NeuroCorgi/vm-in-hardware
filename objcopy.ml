let hex = Printf.sprintf "%02X"

let () =
  let filename = Sys.argv.(1) in
  let input = open_in_bin filename in
  let output = open_out (filename ^ ".hex") in
  let rec loop () =
    let value = hex @@ input_byte input in
    output_string output value;
    let value = hex @@ input_byte input in
    output_string output value;
    output_char output '\n';
    loop ()
  in
  loop ()
