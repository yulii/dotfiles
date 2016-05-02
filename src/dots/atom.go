package main

import (
  "bufio"
  "fmt"
  "log"
  "os"
  "os/exec"
)

func atom(cmd string) {
  switch {
  case cmd == "dump":
    fmt.Println("dump")
    return
  }

}

func apm_list() {
  log.Println("[Exec] apm list --installed --bare")
  //  fmt.Println("[Exec] apm list --installed --bare")
  cmd := exec.Command("apm", "list", "--installed", "--bare")
  stdout, err := cmd.StdoutPipe()

  if err != nil {
		panic(err)
		os.Exit(1)
	}

  file, err := os.Create("/tmp/output-by-golang")

  if err != nil {
		panic(err)
		os.Exit(1)
	}

	cmd.Start()

	scanner := bufio.NewScanner(stdout)
  writer  := bufio.NewWriter(file)
	for scanner.Scan() {
    text := scanner.Text()
		fmt.Println(text)
    writer.WriteString(text)
    writer.WriteString("\n")
	}

	cmd.Wait()

  writer.Flush()
  file.Close()
}
