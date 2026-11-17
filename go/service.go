//go:build ignore

package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

func main() {
	wg := sync.WaitGroup{}

	service := GetUserService()
	go supervisor(service, &wg)
	go client(service, &wg)

	for v := range service.c {
		fmt.Println(v)
	}
}

type ichan (chan User)
type User struct {
	name string
}
type Msg struct {
	id int
	wg *sync.WaitGroup
}
type UserService interface {
	Get(msg Msg)
}

type Database struct{}
type UserSI struct {
	c  ichan
	db *Database
}

func supervisor(service UserSI, wg *sync.WaitGroup) {
	wg.Wait()
	close(service.c)
}

func GetUserService() UserSI {
	res := make(ichan, 1)
	db := new(Database)
	return UserSI {
		res,
		db,
	}
}

func (service UserSI) Get(msg Msg) {
	defer msg.wg.Done()

	service.c <- service.db.Get(msg.id)
}

func client(service UserSI, wg *sync.WaitGroup) {
	for {
		wg.Add(2)
		go service.Get(Msg{rand.Intn(10000), wg})
		time.Sleep(100 * time.Millisecond)
	}
}

func (db Database) Get(id int) User {
	time.Sleep(900 * time.Millisecond)
	return User{
		fmt.Sprintf("Random user %d", id),
	}
}
