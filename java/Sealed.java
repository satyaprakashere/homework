sealed class Animal permits Dog, Cat {}
final class Dog extends Animal {}
final class Cat extends Animal {}

void main() {
    println("Hello to Sealed classes");
}
