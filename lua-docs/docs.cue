package docs

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/docker"
)

// // Docker registry
// registry: {
// 	// Registry accoudnt username
// 	username: dagger.#Input & {string}
// 	// Registry account password or token
// 	secret: dagger.#Input & {dagger.#Secret}
// }

// set secret creds
// dagger input text <key> <value>
// dagger input secret <key> <value>

// Repository
// (e.g dagger input dir repo myfolder/)
repo: dagger.#Input & {dagger.#Artifact}

// Build & Publish documentation
docs: {

	// build image
	image: docker.#Build & {
		source: repo
	}

	// Generate a tag
	tag: dagger.#Input & {*"latest" | string}

	// Target repository (e.g daggercio/ci-test)
	target: dagger.#Input & {string}

	// Push image to remote registry
	remoteImage: docker.#Push & {
		"target": "\(target):\(tag)"
		source: image
		// auth: {
		// 	username: registry.username
		// 	secret:   registry.secret
		// }
	}


}