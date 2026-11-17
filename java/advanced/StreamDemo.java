package advanced;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class StreamDemo {
    record Person(String name, int age, String city) {}

    public static void runDemo() {
        System.out.println("\n--- 2. Advanced Streams Demo ---");
        
        List<Person> people = List.of(
            new Person("Alice", 25, "New York"),
            new Person("Bob", 30, "London"),
            new Person("Charlie", 35, "New York"),
            new Person("David", 40, "London")
        );

        // Group by city and count
        Map<String, Long> cityCounts = people.stream()
            .collect(Collectors.groupingBy(Person::city, Collectors.counting()));

        System.out.println("People per city: " + cityCounts);

        // Find average age in New York
        double avgAgeNY = people.stream()
            .filter(p -> "New York".equals(p.city()))
            .mapToInt(Person::age)
            .average()
            .orElse(0.0);

        System.out.println("Average age in New York: " + avgAgeNY);
    }
}
