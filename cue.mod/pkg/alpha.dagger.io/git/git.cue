// Git operations
package git

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
	"alpha.dagger.io/alpine"
)

// A git repository
#Repository: {
	// Git remote link
	remote: dagger.#Input & {string}

	// Git ref: can be a commit, tag or branch.
	// Example: "main"
	ref: dagger.#Input & {string}

	// (optional) Subdirectory
	subdir: dagger.#Input & {*null | string}

	// (optional) Keep .git directory
	keepGitDir: *false | bool

	// (optional) Add Personal Access Token
	authToken: dagger.#Input & {*null | dagger.#Secret}

	// (optional) Add OAuth Token
	authHeader: dagger.#Input & {*null | dagger.#Secret}

	#up: [
		op.#Load & {
			from: alpine.#Image & {
				package: git: true
			}
		},
		op.#Copy & {
			from: [
				op.#FetchGit & {
					"remote": remote
					"ref":    ref
					if (keepGitDir) {
						keepGitDir: true
					}
					if (authToken != null) {
						"authToken": authToken
					}
					if (authHeader != null) {
						"authHeader": authHeader
					}
				},
			]
			dest: "/repository"
		},
		op.#Exec & {
			dir: "/repository"
			args: [
				"/bin/sh",
				"--noprofile",
				"--norc",
				"-eo",
				"pipefail",
				"-c",
				#"""
					code=$(git rev-parse --is-inside-work-tree 2>&1)
					([ "$code" = "true" ] && git remote set-url origin "$REMOTE") || true
					"""#,
			]
			env: REMOTE: remote
		},
		op.#Subdir & {
			dir: "/repository"
		},
		if subdir != null {
			op.#Subdir & {
				dir: subdir
			}
		},
	]
}

// Get the name of the current checked out branch or tag
#CurrentBranch: {
	// Git repository
	repository: dagger.#Artifact @dagger(input)

	// Git branch name
	name: {
		string

		#up: [
			op.#Load & {
				from: alpine.#Image & {
					package: bash: true
					package: git:  true
				}
			},

			op.#Exec & {
				mount: "/repository": from: repository
				dir: "/repository"
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
					#"""
						printf "$(git symbolic-ref -q --short HEAD || git describe --tags --exact-match)" > /name.txt
						"""#,
				]
			},

			op.#Export & {
				source: "/name.txt"
				format: "string"
			},
		]
	} @dagger(output)
}

// List tags of a repository
#Tags: {
	// Git repository
	repository: dagger.#Artifact @dagger(input)

	// Repository tags
	tags: {
		[...string]

		#up: [
			op.#Load & {
				from: alpine.#Image & {
					package: bash: true
					package: jq:   true
					package: git:  true
				}
			},

			op.#Exec & {
				mount: "/repository": from: repository
				dir: "/repository"
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
					#"""
						git tag -l | jq --raw-input --slurp 'split("\n") | map(select(. != ""))' > /tags.json
						"""#,
				]
			},

			op.#Export & {
				source: "/tags.json"
				format: "json"
			},
		]
	} @dagger(output)
}
