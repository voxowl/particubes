package main

import (
	"github.com/gosimple/slug"
	"regexp"
	"strings"
)

// Page describes possible content for one page
// in the documentation.
type Page struct {

	// meta keywords
	Keywords []string `yaml:"keywords,omitempty"`

	// meta description, built from Description
	MetaDescription string `yaml:"-,omitempty"`

	// meta description
	Description string `yaml:"description,omitempty"`

	//
	Title string `yaml:"title,omitempty"`

	// object type being described
	// can be left empty if not an object type page
	Type string `yaml:"type,omitempty"`

	//
	BasicType bool `yaml:"basic-type,omitempty"`

	// Indicates that instances can be created, even if there's no constructor
	Creatable bool `yaml:"creatable,omitempty"`

	// Blocks are a list of displayable content blocks (text, code sample, image)
	// They are displayed before other attributes (constructors, properties, functions)
	Blocks []*ContentBlock `yaml:"blocks,omitempty"`

	Constructors []*Function `yaml:"constructors,omitempty"`

	Properties []*Property `yaml:"properties,omitempty"`

	BuiltIns []*Property `yaml:"built-ins,omitempty"`

	Functions []*Function `yaml:"functions,omitempty"`

	// not set in YAML, set dynamically when parsing files
	ResourcePath string `yaml:"-"`
}

type Function struct {
	Name        string      `yaml:"name,omitempty"`
	Arguments   []*Argument `yaml:"arguments,omitempty"`
	Description string      `yaml:"description,omitempty"`
	Samples     []*Sample   `yaml:"samples,omitempty"`
	Return      []*Value    `yaml:"return,omitempty"`
}

type Argument struct {
	Name     string `yaml:"name,omitempty"`
	Type     string `yaml:"type,omitempty"`
	Optional bool   `yaml:"optional,omitempty"`
}

type Value struct {
	Type        string `yaml:"type,omitempty"`
	Description string `yaml:"description,omitempty"`
}

type Sample struct {
	Code  string `yaml:"code,omitempty"`
	Media string `yaml:"media,omitempty"`
}

func SampleHasCodeAndMedia(s *Sample) bool {
	return s.Code != "" && s.Media != ""
}

type Property struct {
	Name        string    `yaml:"name,omitempty"`
	Type        string    `yaml:"type,omitempty"`
	Description string    `yaml:"description,omitempty"`
	Samples     []*Sample `yaml:"samples,omitempty"`
	ReadOnly    bool      `yaml:"read-only,omitempty"`
}

// Only one attribute can be set, others will
// be ignored if set.
type ContentBlock struct {
	Text string `yaml:"text,omitempty"`
	// Lua code
	Code  string   `yaml:"code,omitempty"`
	List  []string `yaml:"list,omitempty"`
	Title string   `yaml:"title,omitempty"`
	// Can be a relative link to an image, a link to a youtube video...
	Media string `yaml:"media,omitempty"`
}

// Returns best possible title for page
func (p *Page) GetTitle() string {
	if p.Type != "" {
		return p.Type
	}
	return p.Title
}

// IsNotCreatableObject returns true if the page describes an object
// that can't be created, has to be accessed through its global variable.
func (p *Page) IsNotCreatableObject() bool {
	return p.Creatable == false && p.BasicType == false && p.Type != "" && (p.Constructors == nil || len(p.Constructors) == 0)
}

func getTypeLink(str string) string {

	str = strings.TrimSuffix(str, "]")
	str = strings.TrimPrefix(str, "[")

	if route, ok := typeRoutes[str]; ok {
		str = "<a class=\"type\" href=\"" + route + "\">" + str + "</a>"
	}

	return str
}

func (p *Page) Sanitize() {

	reInlineCode := regexp.MustCompile("`([^`]+)`")
	inlineCodeReplacement := `<span class="code">$1</span>`
	inlineCodeReplacementMetaDescription := `$1`

	reLink := regexp.MustCompile(`\[([^\]]+)\]\(([^)]+)\)`)
	linkReplacement := `<a href="$2">$1</a>`
	linkReplacementMetaDescription := `$1`

	reTypeLink := regexp.MustCompile(`\[([A-Za-z]+)\]`)
	typeLinkReplacementMetaDescription := `$1`

	if p.Description != "" {
		p.Description = strings.TrimSpace(p.Description)
		p.MetaDescription = p.Description
		p.Description = strings.ReplaceAll(p.Description, "\n", "<br>")
		p.Description = reInlineCode.ReplaceAllString(p.Description, inlineCodeReplacement)
		p.Description = reLink.ReplaceAllString(p.Description, linkReplacement)
		p.Description = reTypeLink.ReplaceAllStringFunc(p.Description, getTypeLink)

		p.MetaDescription = strings.ReplaceAll(p.MetaDescription, "\n", " ")
		p.MetaDescription = reInlineCode.ReplaceAllString(p.MetaDescription, inlineCodeReplacementMetaDescription)
		p.MetaDescription = reLink.ReplaceAllString(p.MetaDescription, linkReplacementMetaDescription)
		p.MetaDescription = reTypeLink.ReplaceAllString(p.MetaDescription, typeLinkReplacementMetaDescription)
	}

	if p.Blocks != nil {
		for _, b := range p.Blocks {
			if b.Text != "" {
				b.Text = strings.TrimSpace(b.Text)
				b.Text = strings.ReplaceAll(b.Text, "\n", "<br>")
				b.Text = reInlineCode.ReplaceAllString(b.Text, inlineCodeReplacement)
				b.Text = reLink.ReplaceAllString(b.Text, linkReplacement)
				b.Text = reTypeLink.ReplaceAllStringFunc(b.Text, getTypeLink)
			}
		}
	}

	if p.Constructors != nil {
		for _, c := range p.Constructors {
			if c.Description != "" {
				c.Description = strings.TrimSpace(c.Description)
				c.Description = strings.ReplaceAll(c.Description, "\n", "<br>")
				c.Description = reInlineCode.ReplaceAllString(c.Description, inlineCodeReplacement)
				c.Description = reLink.ReplaceAllString(c.Description, linkReplacement)
				c.Description = reTypeLink.ReplaceAllStringFunc(c.Description, getTypeLink)
			}
		}
	}

	if p.Functions != nil {
		for _, f := range p.Functions {
			if f.Description != "" {
				f.Description = strings.TrimSpace(f.Description)
				f.Description = strings.ReplaceAll(f.Description, "\n", "<br>")
				f.Description = reInlineCode.ReplaceAllString(f.Description, inlineCodeReplacement)
				f.Description = reLink.ReplaceAllString(f.Description, linkReplacement)
				f.Description = reTypeLink.ReplaceAllStringFunc(f.Description, getTypeLink)
			}
		}
	}

	if p.Properties != nil {
		for _, prop := range p.Properties {
			if prop.Description != "" {
				prop.Description = strings.TrimSpace(prop.Description)
				prop.Description = strings.ReplaceAll(prop.Description, "\n", "<br>")
				prop.Description = reInlineCode.ReplaceAllString(prop.Description, inlineCodeReplacement)
				prop.Description = reLink.ReplaceAllString(prop.Description, linkReplacement)
				prop.Description = reTypeLink.ReplaceAllStringFunc(prop.Description, getTypeLink)
			}
		}
	}

	if p.BuiltIns != nil {
		for _, b := range p.BuiltIns {
			if b.Description != "" {
				b.Description = strings.TrimSpace(b.Description)
				b.Description = strings.ReplaceAll(b.Description, "\n", "<br>")
				b.Description = reInlineCode.ReplaceAllString(b.Description, inlineCodeReplacement)
				b.Description = reLink.ReplaceAllString(b.Description, linkReplacement)
				b.Description = reTypeLink.ReplaceAllStringFunc(b.Description, getTypeLink)
			}
		}
	}
}

func GetAnchorLink(s string) string {
	return slug.Make(s)
}
