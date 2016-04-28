package main

import (
  "fmt"
  "os"
)

func main() {
  fmt.Println("os.Args: ", os.Args)

  switch {
  case os.Args[1] == "atom":
  	fmt.Println("atom")
    return
  }
  fmt.Println("unknown")
  // apm_list()
}
