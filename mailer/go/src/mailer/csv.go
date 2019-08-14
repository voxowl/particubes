package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"strings"
	"unicode"

	"golang.org/x/text/transform"
	"golang.org/x/text/unicode/norm"
)

// ColumnIndexes store column index for each field of interest
type ColumnIndexes struct {
	FirstName  int
	LastName   int
	Username   int
	Addr1      int
	Addr2      int
	Code       int
	City       int
	State      int
	CountryISO int
	Email      int
}

// Entry represents a CSV entry
type Entry struct {
	FirstName  string
	LastName   string
	Username   string
	Addr1      string
	Addr2      string
	Code       string
	City       string
	State      string
	CountryISO string
	Email      string
}

// ProcessCSV reads CSV and returns an array of Entry
func processCSV(r io.Reader) ([]*Entry, error) {
	reader := csv.NewReader(r)
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	ci := &ColumnIndexes{FirstName: -1, LastName: -1, Username: -1, Addr1: -1, Addr2: -1, Code: -1, City: -1, State: -1, CountryISO: -1, Email: -1}

	colHeaders := records[0]
	for i, colHeader := range colHeaders {
		// making comparison more permissive
		c := strings.ToLower(colHeader)
		c = strings.Replace(c, " ", "", -1) // remove all spaces

		if c == "prénom" || c == "firstname" {
			ci.FirstName = i
		} else if c == "nom" || c == "name" || c == "lastname" || c == "shippingname" {
			ci.LastName = i
		} else if c == "adresse" || c == "addr1" || c == "address1" || c == "address" || c == "shippingaddress1" {
			ci.Addr1 = i
		} else if c == "complémentd'adresse" || c == "addr2" || c == "address2" || c == "shippingaddress2" {
			ci.Addr2 = i
		} else if c == "codepostal" || c == "zipcode" || c == "postalcode" || c == "shippingzip" {
			ci.Code = i
		} else if c == "city" || c == "ville" || c == "shippingcity" {
			ci.City = i
		} else if c == "pays" || c == "country" || c == "countrycode" || c == "shippingcountry" {
			ci.CountryISO = i
		} else if c == "state" || c == "shippingprovince" {
			ci.State = i
		} else if c == "email" || c == "e-mail" || strings.Contains(c, "email") {
			ci.Email = i
		} else if c == "username" || c == "nickname" {
			ci.Username = i
		}
	}

	entries := make([]*Entry, 0)

	for i := 1; i < len(records); i++ {
		record := records[i]

		entry := &Entry{}

		if ci.FirstName > -1 {
			entry.FirstName = record[ci.FirstName]
		}

		if ci.LastName > -1 {
			entry.LastName = record[ci.LastName]
		}

		if ci.Username > -1 {
			entry.Username = record[ci.Username]
		}

		if ci.Addr1 > -1 {
			entry.Addr1 = record[ci.Addr1]
		}

		if ci.Addr2 > -1 {
			entry.Addr2 = record[ci.Addr2]
		}

		if ci.Code > -1 {
			entry.Code = record[ci.Code]
		}

		if ci.City > -1 {
			entry.City = record[ci.City]
		}

		if ci.CountryISO > -1 {
			entry.CountryISO = record[ci.CountryISO]
		}

		if ci.State > -1 {
			entry.State = record[ci.State]
		}

		if ci.Email > -1 {
			entry.Email = record[ci.Email]
		}

		entries = append(entries, entry)
	}

	return entries, nil
}

func isMn(r rune) bool {
	return unicode.Is(unicode.Mn, r) // Mn: nonspacing marks
}

func removeAccents(s string) string {
	t := transform.Chain(norm.NFD, transform.RemoveFunc(isMn), norm.NFC)
	output, _, e := transform.String(t, s)
	if e != nil {
		panic(e)
	}
	fmt.Println(output)
	return output
}
