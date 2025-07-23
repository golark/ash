package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"time"
)

type GenerateResponse struct {
	Command string `json:"command"`
}

type HealthResponse struct {
	Status string `json:"status"`
	Model  string `json:"model"`
}

func pingServer(serverURL string) {
	endpoint := fmt.Sprintf("%s/health", serverURL)
	resp, err := http.Get(endpoint)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Ping failed: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		fmt.Fprintf(os.Stderr, "❌ Server responded with status code: %s\n", resp.Status)
		os.Exit(1)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to read response\n")
		os.Exit(1)
	}

	var healthResp HealthResponse
	if err := json.Unmarshal(body, &healthResp); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to parse response\n")
		os.Exit(1)
	}

	fmt.Printf("✅ Pong! Server is running (model: %s)\n", healthResp.Model)
}

func waitForServer(serverURL string, timeoutSeconds int) {
	endpoint := fmt.Sprintf("%s/health", serverURL)
	start := time.Now()
	for {
		resp, err := http.Get(endpoint)
		if err == nil && resp.StatusCode == 200 {
			defer resp.Body.Close()
			fmt.Println("✅ ash server is alive!")
			return
		}
		if time.Since(start) > time.Duration(timeoutSeconds)*time.Second {
			fmt.Fprintf(os.Stderr, "❌ Timed out waiting for ash server to come alive (%d seconds)\n", timeoutSeconds)
			os.Exit(1)
		}
		time.Sleep(1 * time.Second)
	}
}

func main() {
	quiet := flag.Bool("quiet", false, "Suppress extra output")
	ping := flag.Bool("ping", false, "Ping the server to test connectivity")
	wait := flag.Bool("wait", false, "Wait for the server to come alive before proceeding (up to 30s)")
	server := flag.String("server", "http://localhost:8765", "ash server URL")
	flag.Parse()

	if *wait {
		waitForServer(*server, 30)
		return
	}

	if *ping {
		pingServer(*server)
		return
	}

	if flag.NArg() == 0 {
		fmt.Println("Usage: ash-client [--quiet] [--ping] [--wait] [--server URL] <query>")
		os.Exit(1)
	}

	query := flag.Arg(0)
	endpoint := fmt.Sprintf("%s/generate?q=%s", *server, url.QueryEscape(query))
	resp, err := http.Get(endpoint)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ ash server is not running or unreachable!\n")
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		fmt.Fprintf(os.Stderr, "❌ Server error: %s\n", resp.Status)
		os.Exit(1)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to read response\n")
		os.Exit(1)
	}

	var genResp GenerateResponse
	if err := json.Unmarshal(body, &genResp); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Failed to parse response\n")
		os.Exit(1)
	}

	if *quiet {
		fmt.Println(genResp.Command)
	} else {
		fmt.Printf("✅ Command: %s\n", genResp.Command)
	}
}
