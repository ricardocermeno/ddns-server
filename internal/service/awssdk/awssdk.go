package awssdk

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	r53 "github.com/aws/aws-sdk-go/service/route53"
)

var SessionAws = session.Must(session.NewSessionWithOptions(session.Options{
	SharedConfigState: session.SharedConfigEnable,
}))

var DynamoSVC = dynamodb.New(SessionAws)
var Route53SVC = r53.New(SessionAws)
