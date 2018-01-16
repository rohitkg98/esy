include CommandExprParser

let parse v =
  let lexbuf = Lexing.from_string v in
  Ok (read [] lexbuf)

type scope = name -> string option

let render ?(pathSep="/") ?(colon=":") ~(scope : scope) (string : string) =
  let open EsyLib.Result in

  let lookup name = match scope name with
  | Some value -> Ok value
  | None ->
    let name = String.concat "." name in
    let msg = Printf.sprintf "undefined variable: %s" name in
    Error msg
  in

  let renderExpr tokens =
    let f segments = function
    | Var name -> let%bind v = lookup name in Ok (v::segments)
    | EnvVar name -> let%bind v = lookup ["$scope"; name] in Ok (v::segments)
    | Literal v -> Ok (v::segments)
    | Colon -> Ok (colon::segments)
    | PathSep -> Ok (pathSep::segments)
    in
    let%bind segments = listFoldLeft ~f ~init:[] tokens in
    Ok (segments |> List.rev |> String.concat "")
  in

  let%bind tokens = parse string in
  let f segments (tok : token) =
    match tok with
    | String v -> Ok(v::segments)
    | Expr tokens -> let%bind v = renderExpr tokens in Ok (v::segments)
  in
  let%bind segments = listFoldLeft ~f ~init:[] tokens in
  Ok (segments |> List.rev |> String.concat "")