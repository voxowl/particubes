package calvados

import (
	"html/template"
	"io/ioutil"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/Sirupsen/logrus"
	"github.com/blevesearch/bleve"
	"github.com/gdevillele/frontparser"
	"github.com/gin-gonic/contrib/gzip"
	"github.com/gin-gonic/contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/shurcooL/github_flavored_markdown"

	"util/fsutil"
	"util/interfaceConv"
)

// TODO: gdevillele:
//
// - language should be detected by a middleware and stored in the *gin.Context
//
//
//

type PreprocFunc func(c *Calvados) error
type CustomRouteFunc func(*gin.Context, *Calvados)

type CustomRoute struct {
	method   string
	path     string
	function CustomRouteFunc
}

func NewCustomRoute(method, path string, function CustomRouteFunc) CustomRoute {
	return CustomRoute{method, path, function}
}

type Config struct {
	DefaultLanguage  string
	DefaultPageTitle string
	SearchBar        bool
}

// use this function to create a Config object please
func NewConfig(defaultLanguage string, defaultPageTitle string, searchBar bool) Config {
	return Config{
		DefaultLanguage:  defaultLanguage,
		DefaultPageTitle: defaultPageTitle,
		SearchBar:        searchBar,
	}
}

type Calvados struct {
	redirections map[string]string
	templateDirs []string
	preprocFuncs []PreprocFunc
	searchIndex  bleve.Index
	config       Config
	customRoutes []CustomRoute
}

// Default returns a Calvados server with default configuration
func Default() *Calvados {

	mapping := bleve.NewIndexMapping()
	index, _ := bleve.NewMemOnly(mapping)
	// TODO: handle error

	return &Calvados{
		redirections: make(map[string]string),
		templateDirs: make([]string, 0),
		preprocFuncs: make([]PreprocFunc, 0),
		config:       NewConfig("en", "Default Title", false),
		searchIndex:  index,
		customRoutes: []CustomRoute{},
	}
}

// WithConfig returns a Calvados server with given Config
func WithConfig(config Config) *Calvados {

	mapping := bleve.NewIndexMapping()
	index, _ := bleve.NewMemOnly(mapping)
	// TODO: handle error

	return &Calvados{
		redirections: make(map[string]string),
		templateDirs: make([]string, 0),
		preprocFuncs: make([]PreprocFunc, 0),
		config:       config,
		searchIndex:  index,
		customRoutes: []CustomRoute{},
	}
}

func (c *Calvados) AddCustomRoute(customRoute CustomRoute) {
	c.customRoutes = append(c.customRoutes, customRoute)
}

func (c *Calvados) AddPreprocessorFunc(f PreprocFunc) {
	c.preprocFuncs = append(c.preprocFuncs, f)
}

func (c *Calvados) AddTemplateDir(path string) {
	c.templateDirs = append(c.templateDirs, path)
}

// serves static and markdown content in /www
// serves static content in /style
func (calva *Calvados) Run(hostAndPort string) error {

	// Execute preprocessor functions
	err := calva.executePreprocessorFunctions()
	if err != nil {
		logrus.Fatalln("[calvados] [preprocessor]", err.Error())
	}

	// Create gin router
	router := gin.Default()

	// Load templates
	err = calva.loadTemplates(router)
	if err != nil {
		logrus.Fatalln("[calvados] [loadTemplates]", err.Error())
	}

	router.Use(gzip.Gzip(gzip.DefaultCompression))
	router.Use(calva.MWAddSecurityHTTPHeaders)
	router.Use(calva.MWCheckForUnexposedPath)
	router.Use(static.ServeRoot("/style", "/style"))

	for _, customRoute := range calva.customRoutes {
		switch method := customRoute.method; method {
		case "GET":
			router.GET(customRoute.path, func(c *gin.Context) {
				customRoute.function(c, calva)
			})
		case "POST":
			router.POST(customRoute.path, func(c *gin.Context) {
				customRoute.function(c, calva)
			})
		default:
			logrus.Errorln("custom route method not supported:", method)
		}
	}

	router.GET("/*path", calva.replyForPath)

	router.NoRoute(calva.replyNotFound)

	return router.Run(hostAndPort)
}

//
func (c *Calvados) SetRedirection(alias, canonical string) {
	c.redirections[alias] = canonical
}

////////////////////////////////////////////////////////////
///
/// Unexposed functions
///
////////////////////////////////////////////////////////////

//
func (c *Calvados) executePreprocessorFunctions() error {
	for _, f := range c.preprocFuncs {
		err := f(c)
		if err != nil {
			return err
		}
	}
	return nil
}

// loadTemplates loads as templates all the files (direct children only)
// present in the directories listed in c.templateDirs.
func (c *Calvados) loadTemplates(r *gin.Engine) error {
	tmplFiles := make([]string, 0)
	for _, templateDir := range c.templateDirs {
		files, err := ioutil.ReadDir(templateDir)
		if err != nil {
			return err
		}
		for _, file := range files {
			tmplFiles = append(tmplFiles, filepath.Join(templateDir, file.Name()))
		}
	}
	r.LoadHTMLFiles(tmplFiles...)
	return nil
}

////////////////////////////////////////////////////////////
///
/// requests handling (generating HTTP responses)
///
////////////////////////////////////////////////////////////

//
func (calva *Calvados) replyForPath(c *gin.Context) {
	requestPath := c.Param("path")
	logrus.Println("request path:", requestPath)
	requestPathEndsWithSlash := strings.HasSuffix(requestPath, "/")
	// WARNING: this call, removes the trailing '/' if there is any
	resourcePath := filepath.Join("/www", requestPath)
	logrus.Println("resource path:", resourcePath)

	// redirect user if request path can be cleaned
	cleanedPath := cleanPath(requestPath)
	if cleanedPath != requestPath {
		c.Redirect(http.StatusSeeOther, cleanedPath)
		return
	}

	dirExistsAtResourcePath := fsutil.DirectoryExists(resourcePath)

	// here, path has been cleaned and trailing '/' removed if directory not found
	if requestPathEndsWithSlash {
		// - request path ends with a '/'
		if dirExistsAtResourcePath {
			// - request path ends with a '/'
			// - a directory exists at that path
			if mdIndexPath := filepath.Join(resourcePath, "index.md"); fsutil.RegularFileExists(mdIndexPath) {
				// - directory exists
				// - child index.md file found
				// > render that file
				resourcePath = mdIndexPath
			} else if htmlIndexPath := filepath.Join(resourcePath, "index.html"); fsutil.RegularFileExists(htmlIndexPath) {
				// - directory exists
				// - child index.md file not found
				// - child index.html file found
				// > serve that file directly
				replyFile(c, resourcePath)
				return
			} else {
				// - directory exists
				// - child index.md file not found
				// - child index.html file not found
				// > we reply 404 not found
				calva.replyNotFound(c)
				return
			}
		} else if canonicalPath, ok := calva.redirections[requestPath]; ok {
			// - request path ends with a '/'
			// - no directory exists at that path
			// - request path is actually an alias
			// > we redirect the user to the alias' canonical path
			c.Redirect(http.StatusMovedPermanently, canonicalPath) // HTTP 301
			return
		} else {
			// - request path ends with a '/'
			// - no directory exists at that path
			// - request path is not an alias
			// > we redirect to the same path, minus the trailing '/'
			// [[ TEMPORARY HACK because of mistakes in the content ]]
			c.Redirect(http.StatusSeeOther, strings.TrimSuffix(requestPath, "/"))
			return
		}
	} else {
		// request path doesn't end with a '/'
		if fsutil.RegularFileExists(resourcePath) {
			// request path points to an existing file
			replyFile(c, resourcePath)
			return
		} else {
			// request path doesn't point to a regular file
			if mdResource := resourcePath + ".md"; fsutil.RegularFileExists(mdResource) {
				// try adding ".md" to the resource path
				resourcePath = mdResource
			} else if dirExistsAtResourcePath {
				// Request path doesn't end with '/' but it points to a directory.
				// We redirect to the same path but adding a trailing '/'
				c.Redirect(http.StatusSeeOther, requestPath+"/")
				return
			} else if canonicalPath, ok := calva.redirections[requestPath]; ok {
				// request path doesn't end with '/'
				// request path + ".md" doesn't point to an existing file
				// request path doesn't point to an existing directory
				// request path is an alias
				c.Redirect(http.StatusSeeOther, canonicalPath)
				return
			} else {
				// resource path doesn't point to an existing file
				// even with the ".md" suffix
				calva.replyNotFound(c)
				return
			}
		}
	}
	// if we reach this point the file at <resourcePath> should be a markdown file
	calva.ReplyMardown(c, http.StatusOK, resourcePath, nil)
}

// 404 Not Found
func (calva *Calvados) replyNotFound(c *gin.Context) {
	// TODO: gdevillele: maybe use a generic 404 with a "back to homepage" button
	//       (also, maybe a 404 that is not a .md file but a regular html template .tmpl)
	calva.ReplyMardown(c, http.StatusNotFound, "/www/_404.md", nil)
}

// 500 Internal Server Error
func (calva *Calvados) replyInternalServerError(c *gin.Context, errorMessage string) {
	c.HTML(http.StatusInternalServerError, "500.tmpl", gin.H{
		"language": calva.config.DefaultLanguage, // TODO: gdevillele: make this dynamic (multilang support)
		"content":  errorMessage,
	})
}

//
func replyFile(c *gin.Context, path string) {
	c.File(path)
}

//
func (calva *Calvados) ReplyMardown(c *gin.Context, httpStatus int, resourcePath string, params map[string]interface{}) {

	// read markdown file
	mdFileBytes, err := ioutil.ReadFile(resourcePath)
	if err != nil {
		calva.replyInternalServerError(c, err.Error())
		return
	}

	// page's default info
	pageLanguage := calva.config.DefaultLanguage // TODO: gdevillele: make this dynamic (multilang support)
	pageTitle := calva.config.DefaultPageTitle
	pageTemplate := "default.tmpl" // TODO: gdevillele: make this customizable
	pageKeywords := ""
	pageDescription := ""
	pageMdContent := mdFileBytes
	pageFrontmatter := make(map[string]interface{})

	// frontmatter parsing
	// check if file has a frontmatter header
	if frontparser.HasFrontmatterHeader(mdFileBytes) {
		fm, md, err := frontparser.ParseFrontmatterAndContent(mdFileBytes)
		if err != nil {
			calva.replyInternalServerError(c, err.Error())
			return
		}
		pageFrontmatter = fm
		pageMdContent = md
		// find title in frontmatter
		if titleIface, ok := pageFrontmatter["title"]; ok {
			titleStr, err := interfaceConv.ToString(titleIface)
			if err != nil {
				logrus.Println("ERROR: frontmatter title value is not a string.")
			} else {
				pageTitle = titleStr
			}
		}
		// find keywords in frontmatter
		if keywordsIface, ok := pageFrontmatter["keywords"]; ok {
			keywordsStr, err := interfaceConv.ToString(keywordsIface)
			if err != nil {
				logrus.Println("ERROR: frontmatter keywords value is not a string")
			} else {
				pageKeywords = keywordsStr
			}
		}
		// find description in frontmatter
		if descriptionIface, ok := pageFrontmatter["description"]; ok {
			descriptionStr, err := interfaceConv.ToString(descriptionIface)
			if err != nil {
				logrus.Println("ERROR: frontmatter description value is not a string")
			} else {
				pageDescription = descriptionStr
			}
		}
		// find template in frontmatter
		if templateIface, ok := pageFrontmatter["template"]; ok {
			templateStr, err := interfaceConv.ToString(templateIface)
			if err != nil {
				logrus.Println("ERROR: frontmatter template value is not a string")
			} else {
				pageTemplate = templateStr
			}
		}
	}

	contentHtmlBytes := github_flavored_markdown.Markdown(pageMdContent)

	htmlParams := gin.H{
		"language":        pageLanguage, // string (must not be empty)
		"title":           pageTitle,
		"content":         template.HTML(contentHtmlBytes),
		"metaKeywords":    pageKeywords,    // string (can be empty)
		"metaDescription": pageDescription, // string (can be empty)
		"config":          calva.config,
	}

	if params != nil {
		for k, v := range params {
			htmlParams[k] = v
		}
	}

	c.HTML(httpStatus, pageTemplate, htmlParams)
}

////////////////////////////////////////////////////////////
///
/// Middlewares
///
////////////////////////////////////////////////////////////

// Adds the security HTTP headers to all HTTP responses
func (calva *Calvados) MWAddSecurityHTTPHeaders(c *gin.Context) {
	// add CSP header to HTTP responses
	c.Header("Content-Security-Policy", "script-src 'self'")
	// add X-Frame-Options header to HTTP responses
	c.Header("X-Frame-Options", "DENY")
	// add X-XSS-Protection header to HTTP responses
	c.Header("X-XSS-Protection", "1; mode=block")
	// add X-Content-Type-Options header to HTTP responses
	c.Header("X-Content-Type-Options", "nosniff")
}

// returns a middleware that sends a 404 response if the request concerns a
// resource that is not exposed. (if one of the path components starts with '_')
func (calva *Calvados) MWCheckForUnexposedPath(c *gin.Context) {
	path := c.Request.URL.String()    // "/style/main.css"
	pathComponents := splitPath(path) // ["style", "main.css"]
	for _, pathComponent := range pathComponents {
		if strings.HasPrefix(pathComponent, "_") {
			calva.replyNotFound(c)
			c.Abort()
		}
	}
}

////////////////////////////////////////////////////////////
///
/// Utility functions
///
////////////////////////////////////////////////////////////

// splitPath takes a '/' separated path and
// returns a slice containing the path elements
// TODO: gdevillele: mabye use filepath.Split
func splitPath(path string) []string {
	var result []string = make([]string, 0)
	for {
		if len(path) == 0 {
			break
		} else if path[len(path)-1:] == "/" {
			path = path[:len(path)-1]
		}
		dir, file := filepath.Split(path)
		if len(file) > 0 {
			result = append([]string{file}, result...)
		}
		path = dir
	}
	return result
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
