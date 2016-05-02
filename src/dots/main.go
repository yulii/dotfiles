package main

import (
  "fmt"
  "os"
)

func main() {
  fmt.Println("os.Args: ", os.Args)

  switch {
  case os.Args[1] == "atom":
    atom(os.Args[2])
    return
  }
  fmt.Println("unknown")
  // apm_list()
}
