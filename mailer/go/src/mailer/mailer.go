package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"

	"golang.org/x/text/encoding/charmap"

	htmlTemplate "html/template"
	txtTemplate "text/template"

	"github.com/gdevillele/frontparser"
	blackfriday "gopkg.in/russross/blackfriday.v2"

	mailjet "github.com/mailjet/mailjet-apiv3-go"
)

var (
	templateTXT  *txtTemplate.Template
	templateHTML *htmlTemplate.Template
)

func main() {

	if len(os.Args) != 5 {
		log.Fatalln("Usage: mailer entries.csv config.json content.md html.tmpl txt.tmpl")
	}

	// LOAD TEMPLATES

	htmlTemplateBytes, err := ioutil.ReadFile(os.Args[4])
	if err != nil {
		log.Fatalln(err)
	}

	temporaryTemplateHTML, err := txtTemplate.New("template-html").Parse(string(htmlTemplateBytes))
	if err != nil {
		log.Fatalln(err)
	}

	// LOAD CSV

	entries, err := readCSV(os.Args[1])
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println("entries:", len(entries))

	// LOAD CONFIG

	config, err := readConfig(os.Args[2])
	if err != nil {
		log.Fatalln("ERROR:", err)
	}

	fmt.Println("config:", config)

	// PARSE MARKDOWN

	parsedMarkdown, err := parseMarkdown(os.Args[3])
	if err != nil {
		log.Fatalln("ERROR:", err)
	}

	// USE MARKDOWN AS HTML CONTENT

	buf := &bytes.Buffer{}
	err = temporaryTemplateHTML.Execute(buf, parsedMarkdown)
	if err != nil {
		log.Fatalln("❌ EMAIL HTML TEMPLATE ERROR:", err)
	}

	// BUILD FINAL HTML TEMPLATE

	templateHTML, err = htmlTemplate.New("template-html").Parse(buf.String())
	if err != nil {
		log.Fatalln(err)
	}

	templateTXT, err = txtTemplate.New("template-txt").Parse(parsedMarkdown.Txt)
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Printf("%#v\n", parsedMarkdown)
	fmt.Println("buf:", buf.String())

	// SEND EMAILS !!

	mailjetClient := mailjet.NewMailjetClient(config.MailJetAPIKey, config.MailJetAPISecret)

	for _, entry := range entries {

		if entry.Email == "" {
			fmt.Println("empty email address (username:", entry.Username+")")
			continue
		}

		buf = &bytes.Buffer{}
		err = templateHTML.Execute(buf, entry)
		if err != nil {
			fmt.Println("❌ EMAIL HTML TEMPLATE ERROR:", err)
			continue
		}
		htmlContent := buf.String()

		// INLINE STYLE
		// gmail (among others I guess) only supports inline styles...
		// so we have to do this, and should ideally remove all our
		// <style> definitions in email templates.

		htmlContent = strings.ReplaceAll(htmlContent, "<p", "<p style=\"margin:0;padding:0;padding-bottom:20px;color:#FFFFFF;\"")
		htmlContent = strings.ReplaceAll(htmlContent, "<h1", "<h1 style=\"margin:0;padding:0;padding-bottom:20px;color:#FFFFFF;\"")
		htmlContent = strings.ReplaceAll(htmlContent, "<h2", "<h2 style=\"margin:0;padding:0;padding-bottom:20px;color:#FFFFFF;\"")
		htmlContent = strings.ReplaceAll(htmlContent, "<h3", "<h3 style=\"margin:0;padding:0;padding-bottom:20px;color:#FFFFFF;\"")
		htmlContent = strings.ReplaceAll(htmlContent, "<h4", "<h4 style=\"margin:0;padding:0;padding-bottom:20px;color:#FFFFFF;\"")
		htmlContent = strings.ReplaceAll(htmlContent, "<ul", "<ul style=\"margin:0;padding:0;padding-bottom:20px;color:#FFFFFF;margin-left:30px;\"")
		htmlContent = strings.ReplaceAll(htmlContent, "<a", "<a style=\"text-decoration:none;color:#45c5d2;\"")

		buf = &bytes.Buffer{}
		err = templateTXT.Execute(buf, entry)
		if err != nil {
			fmt.Println("❌ EMAIL TXT TEMPLATE ERROR:", err)
			continue
		}
		plainTextContent := buf.String()

		messagesInfo := []mailjet.InfoMessagesV31{
			mailjet.InfoMessagesV31{
				From: &mailjet.RecipientV31{
					Email: parsedMarkdown.SenderEmail,
					Name:  parsedMarkdown.SenderName,
				},
				To: &mailjet.RecipientsV31{
					mailjet.RecipientV31{
						Email: entry.Email,
						Name:  "",
					},
				},
				Subject:  parsedMarkdown.Title,
				TextPart: plainTextContent,
				HTMLPart: htmlContent,
				CustomID: "",
			},
		}
		messages := mailjet.MessagesV31{Info: messagesInfo}

		_, err = mailjetClient.SendMailV31(&messages)
		if err != nil {
			log.Println("MAILJET ERROR:", err)
			continue
		}

		fmt.Println("email sent to", entry.Email)
	}

	log.Println("success")
}

// ParsedMarkdown ...
type ParsedMarkdown struct {
	HTML        string
	Txt         string
	Title       string
	Description string
	Keywords    string
	SenderEmail string
	SenderName  string
}

func parseMarkdown(markdownPath string) (*ParsedMarkdown, error) {

	// read markdown file
	mdFileBytes, err := ioutil.ReadFile(markdownPath)
	if err != nil {
		return nil, err
	}

	resp := &ParsedMarkdown{}

	// page's default info
	pageMdContent := mdFileBytes
	pageFrontmatter := make(map[string]interface{})

	// frontmatter parsing
	// check if file has a frontmatter header
	if frontparser.HasFrontmatterHeader(mdFileBytes) {
		fm, md, err := frontparser.ParseFrontmatterAndContent(mdFileBytes)
		if err != nil {
			return nil, err
		}
		pageFrontmatter = fm
		pageMdContent = md

		// find title in frontmatter
		if titleIface, ok := pageFrontmatter["title"]; ok {
			titleStr, err := toString(titleIface)
			if err != nil {
				fmt.Println("ERROR: frontmatter title value is not a string.")
			} else {
				resp.Title = titleStr
			}
		}

		// find keywords in frontmatter
		if keywordsIface, ok := pageFrontmatter["keywords"]; ok {
			keywordsStr, err := toString(keywordsIface)
			if err != nil {
				fmt.Println("ERROR: frontmatter keywords value is not a string")
			} else {
				resp.Keywords = keywordsStr
			}
		}
		// find description in frontmatter
		if descriptionIface, ok := pageFrontmatter["description"]; ok {
			descriptionStr, err := toString(descriptionIface)
			if err != nil {
				fmt.Println("ERROR: frontmatter description value is not a string")
			} else {
				resp.Description = descriptionStr
			}
		}

		// find sender-email in frontmatter
		if templateIface, ok := pageFrontmatter["sender-email"]; ok {
			templateStr, err := toString(templateIface)
			if err != nil {
				fmt.Println("ERROR: sender-email template value is not a string")
			} else {
				resp.SenderEmail = templateStr
			}
		}

		// find sender-name in frontmatter
		if templateIface, ok := pageFrontmatter["sender-name"]; ok {
			templateStr, err := toString(templateIface)
			if err != nil {
				fmt.Println("ERROR: sender-name template value is not a string")
			} else {
				resp.SenderName = templateStr
			}
		}
	}

	resp.Txt = string(pageMdContent)
	resp.HTML = string(blackfriday.Run(pageMdContent))

	return resp, nil
}

////////////////////////////////////////////////////////////
///
/// Utility functions
///
////////////////////////////////////////////////////////////

func toString(i interface{}) (string, error) {
	if str, ok := i.(string); ok {
		return str, nil
	}
	return "", errors.New("interface is not a string")
}

func readCSV(filePath string) ([]*Entry, error) {

	reader, file, err := fileReader(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	csvBytes, err := ioutil.ReadAll(reader)

	csvBytes = bytes.Replace(csvBytes, []byte("\\\""), []byte("\"\""), -1)

	r2 := bytes.NewReader(csvBytes)

	orders, err := processCSV(r2)
	if err != nil {
		return nil, err
	}

	return orders, nil
}

// opens file and returns reader with adapted decoder
func fileReader(filePath string) (io.Reader, *os.File, error) {

	file, err := os.Open(filePath)
	if err != nil {
		return nil, nil, err
	}

	// NOTE: only works on MacOS
	cmd := exec.Command("file", "-I", filePath)
	b, err := cmd.Output()
	if err != nil {
		file.Close()
		return nil, nil, err
	}

	cmdOutput := string(b)

	re := regexp.MustCompile("charset=([-a-zA-Z0-9]+)")

	matches := re.FindStringSubmatch(cmdOutput)

	if len(matches) < 2 {
		// can't find charset, use default reader
		return file, file, nil
	}

	fileCharset := matches[1]

	fileCharset = strings.Replace(fileCharset, "-", "_", -1)
	fileCharset = strings.Replace(fileCharset, " ", "_", -1)
	fileCharset = strings.ToUpper(fileCharset)

	for _, encoding := range charmap.All {

		knownCharset := fmt.Sprint(encoding)

		knownCharset = strings.Replace(knownCharset, "-", "_", -1)
		knownCharset = strings.Replace(knownCharset, " ", "_", -1)
		knownCharset = strings.ToUpper(knownCharset)

		if fileCharset == knownCharset {
			r := encoding.NewDecoder().Reader(file)
			return r, file, nil
		}
	}

	// can't find charset, use default reader
	return file, file, nil
}

/*
// PostEmail ...
type PostEmail struct {
	Post      *types.Post
	Host      string
	Text      PostEmailText
	EmailHash string
	EmailKey  string
}

// PostEmailText ...
type PostEmailText struct {
	DisplayComments string
	Unsubscribe     string
	Settings        string
	Why             string
}

func adminSavePost(c *gin.Context) {
	config, err := ContextGetConfig(c)
	if err != nil {
		serverError(c, err.Error())
		return
	}

	post := &types.Post{}

	err = c.BindJSON(post)

	if err != nil {
		badRequest(c, "incorrect data")
		return
	}

	// validation
	if post.Title == "" {
		badRequest(c, "title can't be empty")
		return
	}

	if post.DateString != "" {
		var d = post.DateString
		if post.TimeString != "" {
			d = d + " " + post.TimeString
		} else {
			// Note: default time could be set in config
			d = d + " " + "8:00am"
		}

		// month/day/year
		t, err := time.ParseInLocation("01/02/2006 3:04pm", d, config.TimeLocation)
		if err != nil {
			badRequest(c, "can't read date")
			return
		}
		fmt.Println("DATE:", t)

		post.Date = int(t.Unix())
	} else {
		// DATE : NOW
		post.Date = int(time.Now().Unix())
	}

	// NOTE: if post.ID == 0, a new post is created in database

	post.Update = int(time.Now().Unix())

	// slug
	// - make from title if empty
	// - fix if not empty but incorrect
	post.Slug = strings.TrimSpace(post.Slug)
	if post.Slug == "" {
		post.Slug = slug.Make(post.Title)
	} else if slug.IsSlug(post.Slug) == false {
		post.Slug = slug.Make(post.Slug)
	}
	post.Slug = strings.Replace(post.Slug, ".", "", -1)

	post.Lang = ContextLang(c)

	// TODO? post.Keywords
	// TODO? post.Description

	post.NbComments = 0

	wasNew := post.IsNew()

	err = post.Save()
	if err != nil {
		serverError(c, err.Error())
		return
	}

	// From there, it's ok to consider success
	// even if emails can't be sent.
	defer ok(c)

	// New Post has been saved successfully
	// send email to subscribers
	if wasNew && post.IsPage == false {
		postEmail := &PostEmail{
			Post: post,
			Host: config.Host,
			Text: PostEmailText{
				DisplayComments: "Afficher les commentaires",
				Unsubscribe:     "Je souhaite me désabonner.",
				Settings:        "⚙️ Afficher les préférences d'abonnement",
				Why:             "Vous recevez ce message suite à l'inscription et validation de cet email sur bloglaurel.com.",
			},
		}

		emailIDs, err := types.RegisteredEmailPostSubscriberIDs()

		if err == nil {

			from := mail.NewEmail("Le blog de Laurel", "noreply@bloglaurel.com")
			subject := "✨📝✨ " + post.Title
			client := sendgrid.NewSendClient(config.SendgridAPIKey)

			go func() {

				for _, emailID := range emailIDs {

					email, found, err := types.RegisteredEmailGet(emailID)
					if err != nil || found == false {
						fmt.Println("❌ can't send newsletter to:", emailID)
						continue
					}

					postEmail.EmailHash = email.ID
					postEmail.EmailKey = email.Key

					buf := &bytes.Buffer{}
					err = postEmailTemplateHTML.Execute(buf, postEmail)
					if err != nil {
						fmt.Println("❌ EMAIL HTML TEMPLATE ERROR:", err)
						continue
					}
					htmlContent := buf.String()

					buf = &bytes.Buffer{}
					err = postEmailTemplateTxt.Execute(buf, postEmail)
					if err != nil {
						fmt.Println("❌ EMAIL TXT TEMPLATE ERROR:", err)
						continue
					}
					plainTextContent := buf.String()

					to := mail.NewEmail("", email.Email)

					message := mail.NewSingleEmail(from, subject, to, plainTextContent, htmlContent)
					_, err = client.Send(message)
					if err != nil {
						log.Println("SENDGRID ERROR:", err)
						continue
					}
				}
			}()
		}
	}
}

type saveSendgridRequest struct {
	APIKey string `json:"apiKey"`
}

func adminSaveSendgrid(c *gin.Context) {
	req := &saveSendgridRequest{}
	err := c.BindJSON(req)
	if err != nil {
		badRequest(c, err.Error())
		return
	}

	config, err := ContextGetConfig(c)
	if err != nil {
		serverError(c, err.Error())
		return
	}

	config.SendgridAPIKey = req.APIKey

	err = config.Save(configPath)
	if err != nil {
		serverError(c, err.Error())
		return
	}

	ok(c)
}*/
