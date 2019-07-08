package interfaceConv

import (
	"errors"
)

//
func ToByteSlice(i interface{}) ([]byte, error) {
	if byteSlice, ok := i.([]byte); ok {
		return byteSlice, nil
	}
	return nil, errors.New("interface is not a byte slice")
}

//
func ToString(i interface{}) (string, error) {
	if str, ok := i.(string); ok {
		return str, nil
	}
	return "", errors.New("interface is not a string")
}

//
func ToArray(i interface{}) ([]interface{}, error) {
	var result []interface{} = make([]interface{}, 0)
	if result, ok := i.([]interface{}); ok {
		return result, nil
	}
	return result, errors.New("interface is not an array")
}

//
func ToStringInterfaceMap(i interface{}) (map[string]interface{}, error) {
	var result map[string]interface{} = make(map[string]interface{})
	mp1, ok := i.(map[interface{}]interface{})
	if ok == false {
		return result, errors.New("interface is not a map[string]interface{}")
	}
	for k, v := range mp1 {
		str, ok := k.(string)
		if ok == false {
			return result, errors.New("interface is not a map[string]interface{}")
		}
		result[str] = v
	}
	return result, nil
}

//
func ToStringArray(i interface{}) ([]string, error) {
	if interfaceArray, ok := i.([]interface{}); ok {
		var stringArray []string = make([]string, 0)
		for _, iface := range interfaceArray {
			if str, ok := iface.(string); ok {
				stringArray = append(stringArray, str)
			} else {
				return nil, errors.New("interface is not a string array")
			}
		}
		return stringArray, nil
	}
	return nil, errors.New("interface is not an array")
}
