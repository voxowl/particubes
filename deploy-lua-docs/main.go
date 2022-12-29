package main

import (
	"context"
	"fmt"
	"os"

	"dagger.io/dagger"
)

func main() {
	fmt.Println("Hello docs deploy! 🙂")

	err := deployLuaDocs()
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
		dagger.WithWorkdir("../.."),     // go to cubzh root directory
	)
	if err != nil {
		return err
	}
	defer client.Close()

	// // create a reference to host root dir
	// dirOpts := dagger.HostDirectoryOpts{
	// 	// exclude the following directories
	// 	Exclude: []string{".git", "ci", "misc"},
	// }
	// src := client.Host().Directory(".", dirOpts)

	// // build container with correct dockerfile
	// buildOpts := dagger.ContainerBuildOpts{
	// 	Dockerfile: "dockerfiles/ubuntu_build_env.Dockerfile",
	// }
	// ciContainer := client.Container().Build(src, buildOpts)

	// // mount host directory to container and go into it
	// ciContainer = ciContainer.WithMountedDirectory("/project", src)
	// ciContainer = ciContainer.WithWorkdir("/project/core/tests/cmake")

	// // execute build commands
	// ciContainer = ciContainer.WithExec([]string{"cmake", "-G", "Ninja", "."})
	// code, err := ciContainer.ExitCode(ctx)
	// if err != nil {
	// 	return err
	// }
	// if code != 0 {
	// 	outErr, err := ciContainer.Stderr(ctx)
	// 	if err != nil {
	// 		return err
	// 	}
	// 	fmt.Println(outErr)
	// 	return errors.New("cmake error")
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

	// fmt.Println("Tests done!")
	return nil
}
