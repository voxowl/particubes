package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"

	"dagger.io/dagger"
	"golang.org/x/crypto/ssh"
)

const (
	LUA_DOCS_DOCKER_IMAGE_NAME string = "registry.particubes.com/lua-docs"
	LUA_DOCS_DOCKER_IMAGE_TAG  string = "latest"
	LUA_DOCS_SERVER_SSH_URL    string = "ssh://ubuntu@3.139.83.217:22" // TODO: secret
)

var (
	LUA_DOCS_SRV_SSH_PRIVATEKEY string = os.Getenv("LUA_DOCS_SRV_SSH_PRIVATEKEY")
	LUA_DOCS_SRV_SSH_KNOWNHOSTS string = os.Getenv("LUA_DOCS_SRV_SSH_KNOWNHOSTS")
	LUA_DOCS_SRV_SSH_USER       string = "ubuntu"
	LUA_DOCS_SRV_SSH_HOST       string = "3.139.83.217"
	LUA_DOCS_SRV_SSH_PORT       string = "22"
)

func main() {
	fmt.Println("⭐️ Deploying Cubzh Lua docs... ⭐️")

	urlRes, err := url.Parse(LUA_DOCS_SERVER_SSH_URL)
	if err != nil {
		fmt.Println("ERROR:", err.Error())
		return
	}
	fmt.Println("User:", urlRes.User)
	fmt.Println("Host:", urlRes.Hostname())
	fmt.Println("Port:", urlRes.Port())

	err = deployLuaDocs()
	if err != nil {
		fmt.Println("Failure. Error:", err.Error())
		os.Exit(1)
	}
	fmt.Println("Success.")
	os.Exit(0)
}

func deployLuaDocs() error {
	// Get background context
	ctx := context.Background()

	// Initialize dagger client
	client, err := dagger.Connect(ctx,
		dagger.WithLogOutput(os.Stdout), // output the logs to the standard output
		dagger.WithWorkdir(".."),        // go to repo's root directory
	)
	if err != nil {
		return err
	}
	defer client.Close()

	// create a reference to host root dir
	// dirOpts := dagger.HostDirectoryOpts{
	// 	// exclude the following directories
	// 	Exclude: []string{".git", ".github"},
	// }
	src := client.Host().Directory("./lua-docs", dagger.HostDirectoryOpts{})

	// build container with correct dockerfile
	buildOpts := dagger.ContainerBuildOpts{
		Dockerfile: "./Dockerfile",
	}
	docsContainer := client.Container().Build(src, buildOpts)
	if docsContainer == nil {
		fmt.Println("❌ docker image build failed")
		return errors.New("docker build failed")
	}

	//
	// TODO: inject commit hash into container & test the image
	//

	// Publish the image on our Docker registry
	// --------------------------------------------------
	{
		fullDockerImageName := LUA_DOCS_DOCKER_IMAGE_NAME + ":" + LUA_DOCS_DOCKER_IMAGE_TAG
		publishOpts := dagger.ContainerPublishOpts{}
		ref, err := docsContainer.Publish(ctx, fullDockerImageName, publishOpts)
		if err != nil {
			fmt.Println("❌ docker image publish failed")
			return err
		}
		fmt.Println("✅ docker image publish OK (" + ref + ")")
	}

	// Update Swarm service with new image
	// --------------------------------------------------
	{
		out, err := remoteRun(
			LUA_DOCS_SRV_SSH_USER,
			LUA_DOCS_SRV_SSH_HOST,
			LUA_DOCS_SRV_SSH_PORT,
			LUA_DOCS_SRV_SSH_PRIVATEKEY,
			"docker service update --image registry.particubes.com/lua-docs:latest lua-docs")
		if err != nil {
			return err
		}
		fmt.Println("✅ docker service update OK")
		fmt.Println("✅", out)
	}

	// // mount host directory to container and go into it
	// ciContainer = ciContainer.WithMountedDirectory("/project", src)
	// ciContainer = ciContainer.WithWorkdir("/project/core/tests/cmake")

	// execute build commands
	// docsContainer = docsContainer.WithExec([]string{})
	// code, err := docsContainer.ExitCode(ctx)
	// if err != nil {
	// 	return err
	// }
	// if code != 0 {
	// 	outErr, err := docsContainer.Stderr(ctx)
	// 	if err != nil {
	// 		return err
	// 	}
	// 	fmt.Println(outErr)
	// 	return errors.New("echo error")
	// }

	// fmt.Println("Running tests in container...")
	// ciContainer = ciContainer.WithExec([]string{"cmake", "--build", ".", "--clean-first"})
	// code, err = ciContainer.ExitCode(ctx)
	// if err != nil {
	// 	return err
	// }
	// if code != 0 {
	// 	outErr, err := ciContainer.Stderr(ctx)
	// 	if err != nil {
	// 		return err
	// 	}
	// 	fmt.Println(outErr)
	// 	return errors.New("cmake --build error")
	// }

	// // exec compiled unit tests program
	// ciContainer = ciContainer.WithExec([]string{"./unit_tests"})
	// output, err := ciContainer.Stdout(ctx)
	// time.Sleep(time.Second * 1) // sleep needed when tests fail (race condition?)
	// if err != nil {
	// 	return err
	// }
	// fmt.Println(output)

	// code, err = ciContainer.ExitCode(ctx)
	// time.Sleep(time.Second * 1) // sleep needed when tests fail (race condition?)
	// if err != nil {
	// 	return err
	// }
	// if code != 0 {
	// 	return errors.New("running error")
	// }

	fmt.Println("✅ Lua docs deployment done!")
	return nil
}

// e.g. output, err := remoteRun("root", "MY_IP", "22", "PRIVATE_KEY", "ls")
func remoteRun(user, addr, port, privateKey, cmd string) (string, error) {
	// privateKey could be read from a file, or retrieved from another storage
	// source, such as the Secret Service / GNOME Keyring
	key, err := ssh.ParsePrivateKey([]byte(privateKey))
	if err != nil {
		return "", err
	}

	// Authentication
	config := &ssh.ClientConfig{
		User: user,
		// https://github.com/golang/go/issues/19767
		// as clientConfig is non-permissive by default
		// you can set ssh.InsercureIgnoreHostKey to allow any host
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), // TODO: use authorized host keys
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(key),
		},
		// alternatively, you could use a password
		// Auth: []ssh.AuthMethod{
		// 	ssh.Password("PASSWORD"),
		// },
	}

	// Connect
	client, err := ssh.Dial("tcp", net.JoinHostPort(addr, port), config)
	if err != nil {
		return "", err
	}
	// defer client.Close() // needed ?

	// Create a session. It is one session per command.
	session, err := client.NewSession()
	if err != nil {
		return "", err
	}
	defer session.Close()

	// Finally, run the command
	var b bytes.Buffer  // import "bytes"
	session.Stdout = &b // get output
	// you can also pass what gets input to the stdin, allowing you to pipe
	// content from client to server
	//      session.Stdin = bytes.NewBufferString("My input")
	err = session.Run(cmd)

	return b.String(), err
}
