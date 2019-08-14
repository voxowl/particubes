package main

import (
	"encoding/json"
	"io/ioutil"
)

// Config ...
type Config struct {
	SendGridAPIKey string `json:"sendgridAPIKey"`
}

func readConfig(filePath string) (*Config, error) {

	jsonString, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	config := &Config{}

	err = json.Unmarshal([]byte(jsonString), config)
	if err != nil {
		return nil, err
	}

	return config, nil
}
