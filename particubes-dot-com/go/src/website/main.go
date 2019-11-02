package main

import (
	"calvados"
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
	config := calvados.NewConfig("en", "Particubes", false)

	c := calvados.WithConfig(config)

	c.AddTemplateDir("/www/_templates")

	c.SetRedirection("/get", "https://itunes.apple.com/app/id1299143207?mt=8")

	c.SetRedirection("/download-mac-alpha", "https://download.particubes.com/Particubes-0.0.2.dmg")

	c.SetRedirection("/discord", "https://discord.gg/NbpdAkv")

	c.AddPreprocessorFunc(CreateRedirectionsFromFrontmatter)

	c.Run(":80")
}
