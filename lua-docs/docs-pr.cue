package docs

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

dagger.#Plan & {
	client: {
		env: {
			GITHUB_SHA:                   string
			DOMAIN:					              string | *"docs.particubes.com"
			PULL_REQUEST_ID:              string
			SSH_PRIVATE_KEY_DOCKER_SWARM: dagger.#Secret
			SSH_KNOWN_HOSTS:              dagger.#Secret
		}
		filesystem: {
			"./lua-docs": read: contents: dagger.#FS
		}
		network: "unix:///var/run/docker.sock": connect: dagger.#Socket // Docker daemon socket
	}

	actions: {
		params: {
			image: {
				ref:      "registry.particubes.com/lua-docs"
				tag:      "pull-\(client.env.PULL_REQUEST_ID)"
				localTag: "lua-docs:pull-\(client.env.PULL_REQUEST_ID)" // name of the image when being run locally
			}
		}

		_dockerCLI: alpine.#Build & {
			packages: {
				bash: {}
				curl: {}
				"docker-cli": {}
				"openssh-client": {}
			}
		}

		#_verifyGithubSHA: bash.#Run & {
			input: _dockerCLI.output
			env: GITHUB_SHA: client.env.GITHUB_SHA
			always: true
			script: contents: #"""
				TRIMMED_URL="$(echo $URL | cut -d '/' -f 1)"
				curl --verbose --fail --connect-timeout 5 --location "$URL" >"$TRIMMED_URL.curl.out" 2>&1

				if ! grep "$GITHUB_SHA" "$TRIMMED_URL.curl.out"
				then
					echo "$GITHUB_SHA not present in the $TRIMMED_URL response:"
					cat "$TRIMMED_URL.curl.out"
					exit 1
				fi
				"""#
		}

		build: {
			luaDocs: docker.#Dockerfile & {
				source: client.filesystem."./lua-docs".read.contents
			}

			_addGithubSHA: core.#WriteFile & {
				input:    luaDocs.output.rootfs
				path:     "/www/github_sha.yml"
				contents: #"""
					keywords: ["particubes", "game", "mobile", "scripting", "cube", "voxel", "world", "docs"]
					title: "Github SHA"
					blocks:
					    - text: "\#(client.env.GITHUB_SHA)"
					"""#
			}
			image: docker.#Image & {
				rootfs: _addGithubSHA.output
				config: luaDocs.output.config
			}
		}

		clean: cli.#Run & {
			host:   client.network."unix:///var/run/docker.sock".connect
			always: true
			env: IMAGE_NAME: params.image.localTag
			command: {
				name: "sh"
				flags: "-c": #"""
					docker rm --force "$IMAGE_NAME"
					"""#
			}
		}

		deploy: {
			publish: docker.#Push & {
				dest:  "\(params.image.ref):\(params.image.tag)"
				image: build.image
			}

			update: cli.#Run & {
				host: "ssh://ubuntu@3.139.83.217"
				always: true
				ssh: {
					key:        client.env.SSH_PRIVATE_KEY_DOCKER_SWARM
					knownHosts: client.env.SSH_KNOWN_HOSTS
				}
				env: DEP: "\(publish.result)" // DEP created with publish
				command: {
					name: "sh"
					flags: "-c": #"""
						docker run \
							--rm -d \
							--name ci-docs-\(client.env.PULL_REQUEST_ID) \
							-p "80" \
							-e VIRTUAL_HOST="pull-\(client.env.PULL_REQUEST_ID).\(client.env.DOMAIN)" \
							-e VIRTUAL_PORT=80 \
							\(params.image.ref):\(params.image.tag)
						"""#
				}
			}

			verify: #_verifyGithubSHA & {
				env: {
					URL: "https://docs.particubes.com/github_sha"
					DEP: "\(update.success)" // DEP created wth run
				}
			}
		}

		undeploy: {
			stopContainer: cli.#Run & {
				host: "ssh://ubuntu@3.139.83.217"
				always: true
				ssh: {
					key:        client.env.SSH_PRIVATE_KEY_DOCKER_SWARM
					knownHosts: client.env.SSH_KNOWN_HOSTS
				}
				command: {
					name: "sh"
					flags: "-c": #"""
						docker stop ci-docs-\(client.env.PULL_REQUEST_ID)
						"""#
				}
			}

			// TODO: remove Docker image from registry
		}
	}
}
