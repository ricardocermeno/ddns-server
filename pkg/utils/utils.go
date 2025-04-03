package utils

import "strings"

const FORWARDED_HEADER = "X-Forwarded-For"
const HOST_HEADER = "Host"

func GetHeaderValue(header string, headers map[string]string) string {

	var result string

	for key, value := range headers {
		if key == header {
			result = strings.Split(value, ",")[0]
			break
		}
	}

	return result
}

func GetIpFromHeaders(headers map[string]string) string {

	return GetHeaderValue(FORWARDED_HEADER, headers)
}

func GetHostFromHeaders(headers map[string]string) string {

	return GetHeaderValue(HOST_HEADER, headers)
}

func IsDefined(value interface{}) bool {
	return value != nil
}

// func ternary(condition bool, trueVlaue any, falseValue any) any {
// 	if condition {
// 		return trueVlaue
// 	} else {
// 		return falseValue
// 	}
// }
