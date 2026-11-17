object ImplicitsDemo {
  case class User(name: String)

  // Implicit parameter
  def greet(implicit user: User): Unit = {
    println(s"Hello, ${user.name}!")
  }

  def runDemo(): Unit = {
    println("\n--- 1. Scala Implicits Demo ---")
    implicit val currentUser: User = User("Alice")
    greet // Picks up currentUser automatically
  }
}
