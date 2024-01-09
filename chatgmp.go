package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"

	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	ctx := context.Background()
	var apiKey = flag.String("api-key", "", "Your API key.")
	flag.Parse()
	if *apiKey == "" {
		log.Fatal("API key is required.")
	}
	// Get Kubernetes info
	scrapeConfig, podsInfo := getKubeInfo()

	// Create the client
	client, err := genai.NewClient(ctx, option.WithAPIKey(*apiKey))
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()
	prom := "You are a Kubernetes and GMP(Google managed service for Prometheus) expert. GMP docs are here https://cloud.google.com/stackdriver/docs/managed-prometheus/setup-managed and the GMP code is https://github.com/GoogleCloudPlatform/prometheus-engine. You will help users setup and debug issues with their nodes, pods, Prometheus scrap configs, etc."
	// For text-only input, use the gemini-pro model
	model := client.GenerativeModel("gemini-pro")
	// Initialize the chat
	cs := model.StartChat()
	cs.History = []*genai.Content{
		&genai.Content{
			Parts: []genai.Part{
				genai.Text(prom),
			},
			Role: "user",
		},
		&genai.Content{
			Parts: []genai.Part{
				genai.Text("Sure, I can help you with that. Here are some Kubernetes commands that you can run to check the state of your nodes, pods, and Prometheus scrape configs:\n\n* To check the status of your nodes:\n```\nkubectl get nodes\n```\n\n* To check the status of your pods:\n```\nkubectl get pods\n```\n\n* To check the status of your Prometheus scrape configs:\n```\nkubectl get servicemonitors\n```\n\n* To check the logs of a specific pod:\n```\nkubectl logs."),
			},
			Role: "model",
		},
	}
	var prompt string
	prompt = fmt.Sprintf("This is the users Prometheus scrape config: %s and their kubernetes pods info: %s. pods that have the prefix 'collector_' are prometheus pods. Limit response to 100 words.", scrapeConfig, podsInfo)
	fmt.Println(prompt)
	for {
		iter := cs.SendMessageStream(ctx, genai.Text(prompt))
		for {
			resp, err := iter.Next()
			if err == iterator.Done {
				break
			}
			if err != nil {
				log.Fatal(err)
			}
			got := resp.Candidates[0]
			for _, part := range got.Content.Parts {
				fmt.Println(part)
			}
		}
		prompt = stringPrompt("What is your prompt?")
	}
}

func stringPrompt(label string) string {
	var s string
	r := bufio.NewReader(os.Stdin)
	for {
		fmt.Fprint(os.Stderr, label+" ")
		s, _ = r.ReadString('\n')
		if s != "" {
			break
		}
	}
	return strings.TrimSpace(s)
}

func getKubeInfo() (string, string) {
	// fmt.Println("Get Kubernetes pods")

	userHomeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("error getting user home dir: %v\n", err)
		os.Exit(1)
	}
	kubeConfigPath := filepath.Join(userHomeDir, ".kube", "config")
	// fmt.Printf("Using kubeconfig: %s\n", kubeConfigPath)

	kubeConfig, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		fmt.Printf("error getting Kubernetes config: %v\n", err)
		os.Exit(1)
	}

	clientset, err := kubernetes.NewForConfig(kubeConfig)
	if err != nil {
		fmt.Printf("error getting Kubernetes clientset: %v\n", err)
		os.Exit(1)
	}

	pods, err := clientset.CoreV1().Pods("").List(context.Background(), v1.ListOptions{})
	if err != nil {
		fmt.Printf("error getting pods: %v\n", err)
		os.Exit(1)
	}
	var podAndState string
	for _, pod := range pods.Items {
		podInfo := fmt.Sprintf("Pod name: %s, phase: %s", pod.Name, pod.Status.Phase)
		for _, containerStatus := range pod.Status.Conditions {
			// podInfo += fmt.Sprintf(", current status:", containerStatus.Status)
			if containerStatus.Message != "" {
				podInfo += fmt.Sprintf(", message: %s", containerStatus.Message)
			}
			if containerStatus.Reason != "" {
				podInfo += fmt.Sprintf(", reason: %s", containerStatus.Reason)
			}
		}
		podAndState += podInfo + "\n"
	}
	var scrapeConfig string
	scrapeConfigMap, err := clientset.CoreV1().ConfigMaps("gmp-system").Get(context.Background(), "collector", v1.GetOptions{})
	if err != nil {
		scrapeConfig = ""
	} else {
		scrapeConfig = scrapeConfigMap.Data["config.yaml"]
	}

	return scrapeConfig, podAndState
}
