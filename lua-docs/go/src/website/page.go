package main

import (
	"fmt"
	"github.com/gosimple/slug"
	"strings"
)

// Page describes possible content for one page
// in the documentation.
type Page struct {

	// meta keywords
	Keywords []string `yaml:"keywords,omitempty"`

	// meta description
	Description string `yaml:"description,omitempty"`

	//
	Title string `yaml:"title,omitempty"`

	// object type being described
	// can be left empty if not an object type page
	Type string `yaml:"type,omitempty"`

	// Blocks are a list of displayable content blocks (text, code sample, image)
	// They are displayed before other attributes (constructors, properties, functions)
	Blocks []*ContentBlock `yaml:"blocks,omitempty"`

	Constructors []*Function `yaml:"constructors,omitempty"`

	Properties []*Property `yaml:"properties,omitempty"`

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
	Name string `yaml:"name,omitempty"`
	Type string `yaml:"type,omitempty"`
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
	return p.Type != "" && (p.Constructors == nil || len(p.Constructors) == 0)
}

func (p *Page) Sanitize() {

	if p.Description != "" {
		p.Description = strings.TrimSpace(p.Description)
		p.Description = strings.ReplaceAll(p.Description, "\n", "<br>")
	}

	if p.Blocks != nil {
		for _, b := range p.Blocks {
			if b.Text != "" {
				b.Text = strings.TrimSpace(b.Text)
				b.Text = strings.ReplaceAll(b.Text, "\n", "<br>")
			}
		}
	}
	if p.Constructors != nil {
		for _, c := range p.Constructors {
			if c.Samples != nil {
				if c.Description != "" {
					c.Description = strings.TrimSpace(c.Description)
					c.Description = strings.ReplaceAll(c.Description, "\n", "<br>")
				}
			}
		}
	}
}

func GetAnchorLink(s string) string {
	return slug.Make(s)
}
