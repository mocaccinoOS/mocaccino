package mos_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("MocaccinoOS X", func() {
	BeforeEach(func() {
		eventuallyConnects()
	})

	Context("Graphics", func() {
		It("installs gnome", func() {
			out, err := sshCommand("luet install -y layers/gnome")
			Expect(out).Should(ContainSubstring("installed"))
			Expect(err).ToNot(HaveOccurred())
		})
	})
})
