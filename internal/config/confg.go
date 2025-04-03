package config

import (
	"os"
)

var TABLE_DNS_NAME = "dns-records-config"

func GetTableDnsName() string {

	envValue := os.Getenv("TABLE_DNS_NAME")

	if len(envValue) > 0 {
		return envValue
	}

	return TABLE_DNS_NAME

}
