package frontparser

import (
	"bytes"
	"errors"

	"gopkg.in/yaml.v2"
)

// error messages
var ErrorFrontmatterNotFound error = errors.New("frontmatter header not found")

var FmYAMLDelimiter []byte = []byte("---")

// var FmTOMLDelimiter []byte = []byte("+++")
// var FmJSONDelimiter []byte = []byte("{")

// returns whether the provided content contains a YAML frontmatter header
func HasFrontmatterHeader(input []byte) bool {
	// remove heading and trailing spaces (and CR, LF, ...)
	input = bytes.TrimSpace(input)
	// test for frontmatter delimiter
	if !bytes.HasPrefix(input, FmYAMLDelimiter) {
		return false
	}
	// trim heading frontmatter delimiter
	input = bytes.TrimPrefix(input, FmYAMLDelimiter)
	// split on frontmatter delimiter to separate frontmatter from the rest
	elements := bytes.SplitN(input, FmYAMLDelimiter, 2)
	if len(elements) != 2 {
		// malformed input
		return false
	}
	// parse frontmatter to validate it is valid YAML
	var out map[string]interface{} = make(map[string]interface{})
	err := yaml.Unmarshal(elements[0], out)
	return err == nil
}

//
func ParseFrontmatter(input []byte) (map[string]interface{}, error) {
	var result map[string]interface{} = make(map[string]interface{})

	// remove heading and trailing spaces (and CR, LF, ...)
	input = bytes.TrimSpace(input)
	// test for frontmatter delimiter
	if !bytes.HasPrefix(input, FmYAMLDelimiter) {
		return result, errors.New("heading frontmatter delimiter not found")
	}
	// trim heading frontmatter delimiter
	input = bytes.TrimPrefix(input, FmYAMLDelimiter)
	// split on frontmatter delimiter to separate frontmatter from the rest
	elements := bytes.SplitN(input, FmYAMLDelimiter, 2)
	if len(elements) != 2 {
		// malformed input
		return result, errors.New("more than two frontmatter delimiters were found")
	}
	// parse frontmatter to validate it is valid YAML
	err := yaml.Unmarshal(elements[0], result)
	return result, err
}

// input is frontmatter + markdown
// return values
// - frontmatter
// - markdown
// - error
func ParseFrontmatterAndContent(input []byte) (map[string]interface{}, []byte, error) {

	var resultFm map[string]interface{} = make(map[string]interface{})
	var resultRest []byte = make([]byte, 0)

	// remove heading and trailing spaces (and CR, LF, ...)
	input = bytes.TrimSpace(input)
	// test for frontmatter delimiter
	if !bytes.HasPrefix(input, FmYAMLDelimiter) {
		return resultFm, resultRest, errors.New("heading frontmatter delimiter not found")
	}

	// trim heading frontmatter delimiter
	input = bytes.TrimPrefix(input, FmYAMLDelimiter)

	// split on frontmatter delimiter to separate frontmatter from the rest
	elements := bytes.SplitN(input, FmYAMLDelimiter, 2)
	if len(elements) != 2 {
		// malformed input
		return resultFm, resultRest, errors.New("more than two frontmatter delimiters were found")
	}

	err := yaml.Unmarshal(elements[0], resultFm)
	if err != nil {
		return resultFm, resultRest, err
	}

	resultRest = elements[1]

	return resultFm, resultRest, nil
}

//
func SplitFrontmatterAndContent(input []byte) ([]byte, []byte, error) {

	resultFm := make([]byte, 0)
	resultRest := make([]byte, 0)

	// remove heading and trailing spaces (and CR, LF, ...)
	input = bytes.TrimSpace(input)
	// test for frontmatter delimiter
	if !bytes.HasPrefix(input, FmYAMLDelimiter) {
		return resultFm, resultRest, errors.New("heading frontmatter delimiter not found")
	}

	// trim heading frontmatter delimiter
	input = bytes.TrimPrefix(input, FmYAMLDelimiter)

	// split on frontmatter delimiter to separate frontmatter from the rest
	elements := bytes.SplitN(input, FmYAMLDelimiter, 2)
	if len(elements) != 2 {
		// malformed input
		return resultFm, resultRest, errors.New("more than two frontmatter delimiters were found")
	}

	resultFm = bytes.TrimSpace(elements[0])
	resultRest = bytes.TrimSpace(elements[1])

	return resultFm, resultRest, nil
}
