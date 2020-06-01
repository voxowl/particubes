package main

import (
	"calvados"
	"fmt"
	"net/http"
	"net/url"

	"github.com/badoux/checkmail"
	"github.com/gin-gonic/gin"
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

// beta form handling route
func HandleBetaForm(c *gin.Context, calva *calvados.Calvados) {
	fmt.Println("💥 HandleBetaForm")
	// get POST field "email" and make sure it is present
	email, ok := c.GetPostForm("email")
	if ok == false {
		// TODO: better error message
		c.String(http.StatusOK, "Error: missing email")
		return
	}

	fmt.Println("-> EMAIL IS:[", email, "]") // TODO: remove this

	// validate email format
	err := checkmail.ValidateFormat(email)
	if err != nil {
		// TODO: better error message
		c.String(http.StatusOK, "Error: email format is invalid")
		return
	}

	// TODO: - store email in database
	//       - send email to <email>

	encodedRedirectPath := url.QueryEscape("/beta/thankyou?email=" + email)
	c.Redirect(http.StatusFound, encodedRedirectPath)
}

// Renders "Thank You" page
func HandleThankYou(c *gin.Context, calva *calvados.Calvados) {

	htmlParams := gin.H{
		"title": "Thank you!",
	}

	// get "email" query param
	emailValue, ok := c.GetQuery("email")
	if ok {
		htmlParams["email"] = emailValue
	}

	c.HTML(http.StatusOK, "betaThankYou.tmpl", htmlParams)
}

//
func main() {
	config := calvados.NewConfig("en", "Particubes", false)

	c := calvados.WithConfig(config)

	c.AddTemplateDir("/www/_templates")

	c.SetRedirection("/get", "https://itunes.apple.com/app/id1299143207?mt=8")

	c.SetRedirection("/download-mac-alpha", "https://download.particubes.com/Particubes-0.0.5.dmg")

	c.SetRedirection("/discord", "https://discord.gg/NbpdAkv")
	c.SetRedirection("/discord-fr", "https://discord.gg/xVSqdJu")

	c.AddPreprocessorFunc(CreateRedirectionsFromFrontmatter)

	c.AddCustomRoute(calvados.NewCustomRoute("GET", "/beta/thankyou", HandleThankYou))
	c.AddCustomRoute(calvados.NewCustomRoute("POST", "/beta/form", HandleBetaForm))

	c.Run(":80")
}
