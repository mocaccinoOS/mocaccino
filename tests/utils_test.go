package mos_test

import (
	"os"
	"time"

	. "github.com/onsi/gomega"
	ssh "golang.org/x/crypto/ssh"
)

func HasDir(s string) {
	out, err := sshCommand("if [ -d " + s + " ]; then echo ok; else echo wrong; fi")
	Expect(err).ToNot(HaveOccurred())
	Expect(out).Should(Equal("ok\n"))
}

func eventuallyConnects(t ...int) {
	dur := 360
	if len(t) > 0 {
		dur = t[0]
	}
	Eventually(func() string {
		out, _ := sshCommand("echo ping")
		return out
	}, time.Duration(time.Duration(dur)*time.Second), time.Duration(5*time.Second)).Should(Equal("ping\n"))
}

func sshCommand(cmd string) (string, error) {
	client, session, err := connectToHost()
	if err != nil {
		return "", err
	}
	defer client.Close()
	out, err := session.CombinedOutput(cmd)
	if err != nil {
		return string(out), err
	}

	return string(out), err
}

func connectToHost() (*ssh.Client, *ssh.Session, error) {
	user := os.Getenv("MOCACCINO_USER")
	if user == "" {
		user = "root"
	}
	pass := os.Getenv("MOCACCINO_PASS")
	if pass == "" {
		pass = "mocaccino"
	}

	host := os.Getenv("MOCACCINO_HOST")
	if host == "" {
		host = "127.0.0.1:2222"
	}

	sshConfig := &ssh.ClientConfig{
		User:    user,
		Auth:    []ssh.AuthMethod{ssh.Password(pass)},
		Timeout: 30 * time.Second, // max time to establish connection
	}

	sshConfig.HostKeyCallback = ssh.InsecureIgnoreHostKey()

	client, err := ssh.Dial("tcp", host, sshConfig)
	if err != nil {
		return nil, nil, err
	}

	session, err := client.NewSession()
	if err != nil {
		client.Close()
		return nil, nil, err
	}

	return client, session, nil
}
