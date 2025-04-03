package main

import (
	"context"
	"fmt"

	"ddns-rcermeno/internal/service/ddns"
	"ddns-rcermeno/pkg/utils"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	fmt.Println("___Init___")

	ip := utils.GetIpFromHeaders(event.Headers)
	host := utils.GetHostFromHeaders(event.Headers)
	err := ddns.UpdateIp(host, ip)

	httpCode := 200
	resText := "good"

	if err != nil {
		fmt.Println("Error: ", err)
		httpCode = 400
		resText = "bad"
	}

	fmt.Println("___End___")

	return events.APIGatewayProxyResponse{
		StatusCode: httpCode,
		Body:       resText + " " + ip,
		Headers: map[string]string{
			"Content-type": "text/plain",
		},
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}
