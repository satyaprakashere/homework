package advanced;

import java.util.ArrayList;
import java.util.List;

public class GenericsDemo {
    // Upper Bounded Wildcard (? extends T) - Producer (Read)
    public static double sum(List<? extends Number> list) {
        double s = 0.0;
        for (Number n : list) s += n.doubleValue();
        return s;
    }

    // Lower Bounded Wildcard (? super T) - Consumer (Write)
    public static void addIntegers(List<? super Integer> list) {
        for (int i = 1; i <= 5; i++) list.add(i);
    }

    public static void runDemo() {
        System.out.println("\n--- 1. Generics Wildcards Demo ---");
        List<Integer> ints = new ArrayList<>();
        addIntegers(ints);
        System.out.println("Sum of ints: " + sum(ints));

        List<Double> doubles = List.of(1.1, 2.2, 3.3);
        System.out.println("Sum of doubles: " + sum(doubles));
    }
}
