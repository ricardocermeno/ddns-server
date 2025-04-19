package dns

import (
	"ddns-rcermeno/internal/service/awssdk"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/service/route53"
)

var hostedZoneId = os.Getenv("HOSTED_ZONE_ID")
var UpserAction = "UPSERT"
var TTL int64 = 60 * 30
var RecordType = "A"

func UpdateRecordSet(domain string, ip string) error {
	comment := fmt.Sprintf("Automatic record performed at %s", time.Now().Local())

	result, err := awssdk.Route53SVC.ChangeResourceRecordSets(&route53.ChangeResourceRecordSetsInput{
		HostedZoneId: &hostedZoneId,
		ChangeBatch: &route53.ChangeBatch{
			Changes: []*route53.Change{
				{
					Action: &UpserAction,
					ResourceRecordSet: &route53.ResourceRecordSet{
						Name: &domain,
						TTL:  &TTL,
						Type: &RecordType,
						ResourceRecords: []*route53.ResourceRecord{
							{
								Value: &ip,
							},
						},
					},
				},
			},
			Comment: &comment,
		},
	})

	if err != nil {
		return err
	}

	fmt.Println(result.GoString())

	return nil
}
