package mos_test

import (
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("MocaccinoOS X", func() {
	BeforeEach(func() {
		eventuallyConnects()
	})

	Context("Graphics", func() {

		It("installs gnome and starts it", func() {
			out, err := sshCommand("luet install -y layers/gnome")
			Expect(out).Should(ContainSubstring("installed"))
			Expect(err).ToNot(HaveOccurred())

			_, err = sshCommand("systemctl start gdm")
			Expect(err).ToNot(HaveOccurred())

			Eventually(func() string {
				out, _ := sshCommand("systemctl status gdm")
				return out
			}, 20*time.Second, 1*time.Second).Should(ContainSubstring("running"))

			Eventually(func() string {
				out, _ := sshCommand("ps aux | grep Xwayland")
				return out
			}, 20*time.Second, 1*time.Second).Should(ContainSubstring("gdm"))

			// Adds user to GDM auto-login
			_, err = sshCommand(`sed -i "s:\[daemon\]:\[daemon\]\nAutomaticLoginEnable=true\nAutomaticLogin=mocaccino\nTimedLoginEnable=true\nTimedLogin=mocaccino\nTimedLoginDelay=0:" /etc/gdm/custom.conf`)
			Expect(err).ToNot(HaveOccurred())

			_, err = sshCommand("systemctl restart gdm")
			Expect(err).ToNot(HaveOccurred())

			Eventually(func() string {
				out, _ := sshCommand("ps aux")
				return out
			}, 50*time.Second, 1*time.Second).Should(ContainSubstring("gnome-shell"))

			// Cleans up
			sshCommand("systemctl stop gdm")

			_, err = sshCommand("luet uninstall -y layers/gnome")
			Expect(err).ToNot(HaveOccurred())

			// Check gnome-shell was removed
			_, err = sshCommand("cat /usr/bin/gnome-shell")
			Expect(err).To(HaveOccurred())
		})

	})
})
