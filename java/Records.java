record Pair<T>(T x, T y) {}
record Point(int x, int y) {}
record Node<T>(T value, Node<T> left, Node<T> right) {}

void main() {
    IO.println("Welcome to Java 27!!");

    final var pair = new Point(1, 2);
    final var pair2 = new Point(1, 2);

    IO.println(String.format("(%s, %s)", pair.x(), pair.y()));
    IO.println(pair == pair2);
    IO.println(pair.equals(pair2));

    final var animal = new Dog();
    IO.println(animal.sound());
}

sealed class Animal permits Dog, Cat {
    String sound() {
        return "Animal sound!";
    }
}

final class Dog extends Animal {
    String sound() {
        return "Bark";
    }
}

final class Cat extends Animal {}
