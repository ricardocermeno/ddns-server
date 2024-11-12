package main

import (
	"context"
	"fmt"
	"strings"

	// "log"
	// "os"
	// "strings"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	fmt.Println("___Init___")
	fmt.Println(event.Headers)

	ip := ""

	for key, value := range event.Headers {
		if key == "X-Forwarded-For" {
			ip = strings.Split(value, ",")[0]
		}
	}
	fmt.Println(ip)
	fmt.Println(event.Body)
	fmt.Println("___End___")

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       "good " + ip,
		Headers: map[string]string{
			"Content-type": "text/plain",
		},
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}
