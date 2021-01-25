package main

import (
	"strings"
)

// Page describes possible content for one page
// in the documentation.
type Page struct {

	// meta keywords
	Keywords []string `json:"keywords,omitempty"`

	// meta description
	Description string `json:"description,omitempty"`

	//
	Title string `json:"title,omitempty"`

	// object type being described
	// can be left empty if not an object type page
	Type string `json:"type,omitempty"`

	// Blocks are a list of displayable content blocks (text, code sample, image)
	// They are displayed before other attributes (constructors, properties, functions)
	Blocks []*ContentBlock `json:"blocks,omitempty"`

	Constructors []*Function `json:"constructors,omitempty"`

	Properties map[string]*Property `json:"properties,omitempty"`

	Functions map[string]*Function `json:"functions,omitempty"`

	// not set in JSON, set dynamically when parsing files
	ResourcePath string `json:"-"`
}

type Function struct {
	Arguments   []*Argument `json:"arguments,omitempty"`
	Description string      `json:"description,omitempty"`
	Samples     []*Sample   `json:"samples,omitempty"`
	Return      []*Value    `json:"return,omitempty"`
}

type Argument struct {
	Name string `json:"name,omitempty"`
	Type string `json:"type,omitempty"`
}

type Value struct {
	Type        string `json:"type,omitempty"`
	Description string `json:"description,omitempty"`
}

type Sample struct {
	Code        string `json:"code,omitempty"`
	ImagePath   string `json:"image,omitempty"`
	Description string `json:"description,omitempty"`
}

type Property struct {
	Type        string    `json:"type,omitempty"`
	Description string    `json:"description,omitempty"`
	Samples     []*Sample `json:"samples,omitempty"`
}

// Only one attribute can be set, others will
// be ignored if set.
type ContentBlock struct {
	Text string `json:"text,omitempty"`
	// Lua code
	Code  string   `json:"code,omitempty"`
	List  []string `json:"list,omitempty"`
	Title string   `json:"title,omitempty"`
	// Can be a relative link to an image, a link to a youtube video...
	Media string `json:"media,omitempty"`
}

// Returns best possible title for page
func (p *Page) GetTitle() string {
	if p.Type != "" {
		return p.Type
	}
	return p.Title
}

func (p *Page) Sanitize() {
	if p.Blocks != nil {
		for _, b := range p.Blocks {
			if b.Text != "" {
				b.Text = strings.TrimSpace(b.Text)
				b.Text = strings.ReplaceAll(b.Text, "\n", "<br>")
			}
		}
	}
}
