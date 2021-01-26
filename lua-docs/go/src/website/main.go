package main

import (
	// "encoding/json"
	"errors"
	"fmt"
	yaml "gopkg.in/yaml.v2"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"text/template"
	"util/fsutil"
)

const (
	contentDirectory = "/www"
	templateFile     = "page.tmpl"
)

var (
	debug                 bool = true
	pages                 map[string]*Page
	pageTemplate          *template.Template
	staticFileDirectories = []string{"js", "style", "media"}
)

//
func main() {

	if os.Getenv("RELEASE") == "1" {
		debug = false
	}

	parseContent()

	for _, staticDir := range staticFileDirectories {
		http.Handle("/"+staticDir+"/", http.StripPrefix("/"+staticDir+"/", http.FileServer(http.Dir(filepath.Join(contentDirectory, staticDir)))))
	}

	http.HandleFunc("/", httpHandler)

	fmt.Println("✨ Particubes documentation running...")

	http.ListenAndServe(":80", nil)
}

func httpHandler(w http.ResponseWriter, r *http.Request) {

	if debug {
		parseContent()
	}

	path := cleanPath(r.URL.Path)

	page, ok := pages[path]
	if ok == false && path != "/" {
		// not found, redirect to /
		fmt.Println("not found:", path)

		if page404, ok := pages["/404"]; ok {
			w.WriteHeader(http.StatusNotFound)
			_ = replyPage(w, page404)
			return
		}

		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	if r.URL.Path != path {
		fmt.Println(r.URL.Path, "!=", path)
		http.Redirect(w, r, path, http.StatusMovedPermanently)
		return
	}

	if page != nil {
		_ = replyPage(w, page)
		return
	}

	replyText(w, "hello world")
}

func replyText(w http.ResponseWriter, text string) {
	fmt.Fprintln(w, text)
}

func replyPage(w http.ResponseWriter, page *Page) error {
	err := pageTemplate.Execute(w, page)
	if err != nil {
		fmt.Println("🔥 error:", err.Error())
	}
	return err
}

func GetTitle(page *Page) string {
	return page.GetTitle()
}

func IsNotCreatableObject(page *Page) bool {
	return page.IsNotCreatableObject()
}

// parseContent is only done once at startup in RELEASE mode.
// Called for each request in DEBUG to consider potential changes.
func parseContent() error {

	var err error

	pages = make(map[string]*Page)

	if !fsutil.DirectoryExists(contentDirectory) {
		return errors.New("content directory is missing")
	}

	templateFilePath := filepath.Join(contentDirectory, templateFile)

	pageTemplate = template.New("page.tmpl").Funcs(template.FuncMap{
		"Join":                  strings.Join,
		"GetTitle":              GetTitle,
		"GetAnchorLink":         GetAnchorLink,
		"SampleHasCodeAndMedia": SampleHasCodeAndMedia,
		"IsNotCreatableObject":  IsNotCreatableObject,
	})

	pageTemplate, err = pageTemplate.ParseFiles(templateFilePath)

	if err != nil {
		fmt.Println("🔥 error:", err.Error())
		return err
	}

	err = filepath.Walk(contentDirectory, func(walkPath string, walkInfo os.FileInfo, walkErr error) (err error) {
		if walkErr != nil {
			return walkErr
		}

		if strings.HasSuffix(walkPath, ".yml") { // YML FILE

			// check if path points to a regular file
			exists := fsutil.RegularFileExists(walkPath)
			if exists {

				var page Page

				file, err := os.Open(walkPath)
				if err != nil {
					return err
				}

				// example: from /www/index.json to /index.json
				trimmedPath := strings.TrimPrefix(walkPath, contentDirectory)

				page.ResourcePath = trimmedPath

				cleanPath := cleanPath(trimmedPath)

				err = yaml.NewDecoder(file).Decode(&page)

				if err != nil {

					page.Title = "Error"
					page.Description = err.Error()

				} else { // page parsed without errors

					page.Sanitize()
				}

				pages[cleanPath] = &page
			}

		} /*else if strings.HasSuffix(walkPath, ".json") { // JSON FILE

			// check if path points to a regular file
			exists := fsutil.RegularFileExists(walkPath)
			if exists {

				var page Page

				file, err := os.Open(walkPath)
				if err != nil {
					return err
				}

				err = json.NewDecoder(file).Decode(&page)

				if err != nil {
					fmt.Println("JSON DECODE ERR:", err.Error())
					return err
				}

				// example: from /www/index.json to /index.json
				trimmedPath := strings.TrimPrefix(walkPath, contentDirectory)

				page.ResourcePath = trimmedPath

				cleanPath := cleanPath(trimmedPath)

				page.Sanitize()

				pages[cleanPath] = &page
			}
		}*/

		return nil
	})

	if err != nil {
		return err
	}

	fmt.Println("content parsed!")
	// fmt.Printf("%4v\n", pages)
	fmt.Println("PAGES:")
	for k, _ := range pages {
		fmt.Println(k)
	}

	return nil
}

// cleanPath cleans a path, lowercases it,
// removes file extension and make it /
// if it refers to /index.
func cleanPath(path string) string {

	cleanPath := filepath.Clean(path)
	cleanPath = strings.ToLower(cleanPath)

	extension := filepath.Ext(cleanPath)
	if extension != "" {
		cleanPath = strings.TrimSuffix(cleanPath, extension)
	}

	if strings.HasSuffix(cleanPath, "/index") {
		cleanPath = strings.TrimSuffix(cleanPath, "/index")
	}

	if cleanPath == "" {
		cleanPath = "/"
	}

	return cleanPath
}
