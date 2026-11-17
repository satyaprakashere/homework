#include <iostream>
#include <string>

// Variadic Template: Recursive sum
template<typename T>
T sum(T v) {
    return v;
}

template<typename T, typename... Args>
T sum(T first, Args... args) {
    return first + sum(args...);
}

// CRTP (Curiously Recurring Template Pattern)
template <typename Derived>
struct Base {
    void interface() {
        static_cast<Derived*>(this)->implementation();
    }
};

struct Derived1 : Base<Derived1> {
    void implementation() {
        std::cout << "Derived1 implementation\n";
    }
};

void run_templates_demo() {
    std::cout << "\n--- 1. Templates Demo ---\n";
    std::cout << "Sum of 1,2,3,4: " << sum(1, 2, 3, 4) << "\n";
    
    Derived1 d;
    d.interface();
}
