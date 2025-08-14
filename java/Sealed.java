sealed class Animal permits Dog, Cat {}
final class Dog extends Animal {}
final class Cat extends Animal {}

void main() {
    System.out.println("Hello to Sealed classes");
}
