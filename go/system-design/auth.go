//go:build ignore

package main

import "fmt"

func main() {
	fmt.Println("Auth is running")

	auth := &Auth{}
	auth.login("prakash", "123456")
	auth.logout()
}

type Auth struct {
	user string
	pass string
}

func (a *Auth) login(user string, pass string) {
	a.user = user
	a.pass = pass
	fmt.Println("User logged in")
}

func (a *Auth) logout() {
	a.user = ""
	a.pass = ""
	fmt.Println("User logged out")
}
