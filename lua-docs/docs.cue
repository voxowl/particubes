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

// to connect to swarm for redeploy
swarmSSHKey: dagger.#Input & {dagger.#Secret}

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
	
	// Tell Swarm to update the lua-docs service using
	// the new "lua-docs:latest" docker image
	// TODO: gdevillele: docker.#Command is supposed to execute a Docker command directly, not an SSH command.
	//                   It likely does the ssh-ing internaly (this is to check with the dagger team)
	deploy: docker.#Command & {
		ssh: {
			// ssh host
			host: "3.139.83.217"
			// ssh user
			user: "ubuntu"
			// private key
			key: swarmSSHKey
		}
		command: "ssh ubuntu@3.139.83.217 -i /id_rsa \"sudo docker service update --image registry.particubes.com/lua-docs:latest lua-docs\""
		// mount the secret as a file
		secret: {
			"/id_rsa": swarmSSHKey
		}
		// this is only so `deploy` depends on `remoteImage`
		env: {
			"ref": remoteImage.ref
		}
	}
}
