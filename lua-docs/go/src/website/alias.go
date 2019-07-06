package main

import (
	"errors"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"util/fsutil"
	"util/interfaceConv"

	"github.com/Sirupsen/logrus"
	"github.com/gdevillele/frontparser"
)

//
func aliasParseMarkdownFiles(rootPath string) (map[string]string, error) {
	// check that rootPath points to a directory
	if !fsutil.DirectoryExists(rootPath) {
		return nil, errors.New("rootPath doesn't point to an existing directory")
	}
	return aliasWalk(rootPath)
}

//
func aliasWalk(root string) (map[string]string, error) {

	var result map[string]string = make(map[string]string)

	err := filepath.Walk(root, func(walkPath string, walkInfo os.FileInfo, walkErr error) (err error) {
		if walkErr != nil {
			return walkErr
		}

		// only consider paths ending with .md
		if strings.HasSuffix(walkPath, ".md") {
			// check if path points to a regular file
			exists := fsutil.RegularFileExists(walkPath)
			if exists {

				fileBytes, err := ioutil.ReadFile(walkPath)
				if err != nil {
					return err
				}
				if frontparser.HasFrontmatterHeader(fileBytes) {

					var out map[string]interface{} = make(map[string]interface{})
					out, err := frontparser.ParseFrontmatter(fileBytes)
					if err != nil {
						return err
					}
					if redirectArrayInterface, existsInMap := out["redirect_from"]; existsInMap {
						aliasesStringArray, err := interfaceConv.ToStringArray(redirectArrayInterface)
						if err != nil {
							// TEMPORARY
							// this is because some md files have a string-typed "aliases" value
							// instead of a []string-type "redirect_from" value
							str, err := interfaceConv.ToString(redirectArrayInterface)
							if err != nil {
								logrus.Println("ERROR:", err.Error())
								return err
							}
							aliasesStringArray = []string{str}
						}

						// example: from /www/index.md to /index.md
						trimmedPath := strings.TrimPrefix(walkPath, root)
						// removes trailing ".md" or "index.md"
						cleanedPath := cleanPath(trimmedPath)

						for _, alias := range aliasesStringArray {
							result[alias] = cleanedPath
						}
					}
				}
			}
		}
		return nil
	})
	if err != nil {
		return result, err
	}
	return result, nil
}

// removes trailing ".md" or trailing "index.md"
func cleanPath(path string) string {
	// check for trailing ".md"
	path = strings.TrimSuffix(path, ".md")
	if strings.HasSuffix(path, "/index") {
		path = strings.TrimSuffix(path, "index")
	}
	return path
}
