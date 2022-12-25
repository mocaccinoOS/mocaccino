package mos_test

import (
	"fmt"
	"strings"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var toIgnore []string = []string{
	"libsamba-debug-samba4.so",
	"libreplace-samba4.so",
	"libgtk-4.so.1",
	"libsystemd-shared-251.so",
	"libcairo-sphinx.so",
	"libtracker-extract.so",	
}	

func pruneOutput(out string) string {
	for _, i := range toIgnore {
		out = strings.ReplaceAll(out, fmt.Sprintf("%s => not found", i), "")
	}
	return out
}

var _ = Describe("MocaccinoOS", func() {
	BeforeEach(func() {
		eventuallyConnects()
	})

	Context("Settings", func() {
		It("has yip folders", func() {
			HasDir("/etc/yip.d")
		})
		It("has default repos", func() {
			out, err := sshCommand("luet repo list")
			Expect(err).ToNot(HaveOccurred())
			Expect(out).Should(ContainSubstring("Luet official Repository"))
			Expect(out).Should(ContainSubstring("mocaccino-repository-index"))
		})
	})

	Context("After install", func() {
		It("upgrades", func() {
			out, err := sshCommand("luet upgrade -y")
			Expect(err).ToNot(HaveOccurred())
			Expect(out).Should(ContainSubstring("Computing upgrade"))
		})
	})

	Context("Lib test", func() {
		It("does not have any broken lib", func() {
			err := SendFile("assets/libtest.sh", "/tmp/libtest.sh", "0777")
			Expect(err).ToNot(HaveOccurred())
			out, err := sshCommand("bash /tmp/libtest.sh")
			Expect(err).ToNot(HaveOccurred())
			Expect(pruneOutput(out)).ShouldNot(ContainSubstring("not found"))
		})
	})
})
