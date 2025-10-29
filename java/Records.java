record Pair<T>(T x, T y) {
}

record Point(int x, int y) {
}

record Node<T>(T value, Node<T> left, Node<T> right) {
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

final class Cat extends Animal {
}

void main() {
    IO.println("Hello, World!");
    IO.println("Welcome to Java!");

    final var pair = new Pair<>(1, 2);
    IO.println(pair.x());
    IO.println(pair.y());
    IO.println(pair);

    final var animal = new Dog();
    IO.println(animal.sound());
}
