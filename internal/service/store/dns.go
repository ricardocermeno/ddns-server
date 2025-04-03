package store

import (
	"ddns-rcermeno/pkg/utils"
	"fmt"

	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

var ips []string
var LIMIT_DEFAULT int32 = 10

var DNS_TABLE_NAME = "DNS"

type DnsRecord struct {
	Domain string
	Ip     string
}

func DNSRecordGetAll(limit *int32) []DnsRecord {

	domains := make([]DnsRecord, 0)

	domains = append(domains, DnsRecord{
		Domain: "test",
		Ip:     "dsfsf",
	})

	return domains
}

func DnsRecordGetById(domain string) (dnsRecord DnsRecord) {

	ddbRecord, err := SVC.GetItem(&dynamodb.GetItemInput{
		TableName: &DNS_TABLE_NAME,
		Key: map[string]*dynamodb.AttributeValue{
			"Domain": {
				S: &domain,
			},
		},
	})

	if utils.IsDefined(err) {
		fmt.Println(err)
		return
	}

	if ddbRecord == nil {
		return
	}

	unmarshalErr := dynamodbattribute.UnmarshalMap(ddbRecord.Item, dnsRecord)

	if unmarshalErr != nil {
		fmt.Println(unmarshalErr)
		return
	}

	return
}

// func DNSRecordGetAll(limit *int32) []DnsRecord {

// 	if limit == nil {
// 		limit = &LIMIT_DEFAULT
// 	}

// 	awsConfig, err := sdkConfig.LoadDefaultConfig(context.TODO())

// 	if err != nil {
// 		fmt.Println(err)
// 	}

// 	ddbClient := ddb.NewFromConfig(awsConfig)

// 	TableName := config.GetTableDnsName()

// 	results, err := ddbClient.Query(context.TODO(), &ddb.QueryInput{
// 		TableName: &TableName,
// 		Limit:     limit,
// 	})

// 	if err != nil {
// 		fmt.Println(err)
// 	}

// 	domains := make([]DnsRecord, 0)

// 	attributevalue.UnmarshalListOfMaps(results.Items, domains)

// 	return domains
// }

func DomainSave(ip string) {
	ips = append(ips, ip)
}

func DnsRecordUpdate(host string, ip string) error {

	item, err := dynamodbattribute.MarshalMap(DnsRecord{
		Ip:     ip,
		Domain: host,
	})

	if err != nil {
		return err
	}

	input := &dynamodb.PutItemInput{
		TableName: &DNS_TABLE_NAME,
		Item:      item,
	}

	_, err = SVC.PutItem(input)

	if utils.IsDefined(err) {
		return err
	}

	return nil
}
