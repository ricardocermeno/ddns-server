package main

import (
	"context"
	"fmt"

	// "log"
	// "os"
	// "strings"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	fmt.Println("___Init___")
	fmt.Println(event.Headers)
	fmt.Println(event.Body)
	fmt.Println("___End___")

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       "Hello Word",
		Headers: map[string]string{
			"Content-type": "application/json",
		},
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}
