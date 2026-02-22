record Pair<T>(T x, T y) {}

//@value
record Point(int x, int y) {}

record Node<T>(T value, Node<T> left, Node<T> right) {}

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
    IO.println("Welcome to Java 25!");

    final var pair = new Point(1, 2);
    final var pair2 = new Point(1, 2);
    
    IO.println(pair.x());
    IO.println(pair.y());
    IO.println(pair == pair2);
    IO.println(pair.equals(pair2));

    final var animal = new Dog();
    IO.println(animal.sound());
}
