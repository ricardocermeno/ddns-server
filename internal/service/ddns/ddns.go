package ddns

import (
	"ddns-rcermeno/internal/service/dns"
	"ddns-rcermeno/internal/service/store"
)

func UpdateIp(host string, ip string) error {

	if dns := store.DnsRecordGetById(host); dns != nil {
		if dns.Ip == ip {
			return nil
		}
	}

	err := store.DnsRecordUpdate(host, ip)

	if err != nil {
		return err
	}

	err = dns.UpdateRecordSet(host, ip)

	if err != nil {
		return err
	}

	return nil

}
