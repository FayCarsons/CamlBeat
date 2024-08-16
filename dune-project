(lang dune 3.16)

(using menhir 3.0)

(wrapped_executables false)

(package
 (name bytebeat)
 (depends
  (ocaml
   (>= "5.2"))
  dune))
