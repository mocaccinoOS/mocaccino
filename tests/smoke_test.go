package mos_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

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
})
