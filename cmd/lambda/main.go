package main

import (
	"context"
	"fmt"
	"net/http"

	"ddns-rcermeno/internal/service/ddns"
	"ddns-rcermeno/pkg/utils"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func buildResponse(httpCode int, body string) events.APIGatewayProxyResponse {
	return events.APIGatewayProxyResponse{
		StatusCode: httpCode,
		Body:       body,
		Headers: map[string]string{
			"Content-type": "text/plain",
		},
	}
}

func handleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	fmt.Println("___Init___")

	var err error

	ip, host := utils.GetIpFromHeaders(event.Headers), utils.GetHostFromHeaders(event.Headers)

	if ip == "" || host == "" {
		fmt.Println("Error: ", "ip or host not found")
		err = fmt.Errorf("ip or host not found")
		return buildResponse(http.StatusBadRequest, err.Error()), nil
	}

	err = ddns.UpdateIp(host, ip)

	if err != nil {
		fmt.Println("Error: ", err)
		return buildResponse(http.StatusBadRequest, err.Error()), nil
	}

	fmt.Println("___End___")

	return buildResponse(http.StatusOK, "good"+" "+ip), nil
}

func main() {
	lambda.Start(handleRequest)
}
