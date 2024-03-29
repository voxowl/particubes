// Maven is a build automation tool for Java
package maven

import (
	"strings"

	"alpha.dagger.io/dagger"
	"alpha.dagger.io/alpine"
	"alpha.dagger.io/os"
)

// A Maven project
#Project: {

	// Application source code
	source: dagger.#Artifact @dagger(input)

	// Extra alpine packages to install
	package: {
		[string]: true | false | string
	} @dagger(input)

	// Environment variables
	env: {
		[string]: string
	} @dagger(input)

	phases: [...string] | *["package"] @dagger(input)
	goals:  [...string] | *[]          @dagger(input)

	// Optional arguments for the script
	args: [...string] | *[] @dagger(input)

	// Build output directory
	build: os.#Dir & {
		from: ctr
		path: "/build"
	} @dagger(output)

	ctr: os.#Container & {
		image: alpine.#Image & {
			"package": package & {
				bash:      true
				openjdk11: true
				maven:     true
			}
		}
		shell: path: "/bin/bash"
		command: """
			opts=( $(echo $MAVEN_ARGS) )
			mvn $MAVEN_GOALS $MAVEN_PHASES ${opts[@]}
			result=$?
			modules=$(mvn -Dexec.executable='pwd' -Dexec.args='${project.artifactId}' exec:exec -q)
			for module in $modules;do
			    source=$(echo "$module/target" | tr -s /)
			    target=$(echo "/build/$module" | tr -s /)
			    mkdir -p  $target;cp -a $source $target 2>/dev/null || : 
			done
			exit $result
			"""
		"env": env & {
			MAVEN_ARGS:   strings.Join(args, "\n")
			MAVEN_PHASES: strings.Join(phases, "\n")
			MAVEN_GOALS:  strings.Join(goals, "\n")
		}
		dir: "/"
		copy: "/": from: source
	}
}
