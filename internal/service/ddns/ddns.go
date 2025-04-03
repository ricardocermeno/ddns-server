package ddns

import (
	"ddns-rcermeno/internal/service/store"
)

func UpdateIp(host string, ip string) error {
	dns := store.DnsRecordGetById(host)

	if dns.Ip == ip {
		return nil
	}

	return store.DnsRecordUpdate(host, ip)
}
