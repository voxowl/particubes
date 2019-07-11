package main

import (
	"os"

	"github.com/gdevillele/calvados"
)

// preprocessor function
func CreateRedirectionsFromFrontmatter(c *calvados.Calvados) error {
	var aliases map[string]string = make(map[string]string)
	var err error = nil
	// generate aliases map
	aliases, err = aliasParseMarkdownFiles("/www")
	if err != nil {
		return err
	}
	for alias, canonical := range aliases {
		c.SetRedirection(alias, canonical)
	}
	return nil
}

//
func main() {
	config := calvados.NewConfig("en", "Particubes - Scripting Documentation", false)

	c := calvados.WithConfig(config)

	c.AddTemplateDir("/www/_templates")

	// c.SetRedirection("/get", "https://itunes.apple.com/app/id1299143207?mt=8")

	c.AddPreprocessorFunc(CreateRedirectionsFromFrontmatter)

	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}

	c.Run(":" + port)
}
