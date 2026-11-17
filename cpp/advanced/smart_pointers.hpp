#include <iostream>
#include <memory>

struct Resource {
    Resource() { std::cout << "Resource acquired\n"; }
    ~Resource() { std::cout << "Resource released\n"; }
    void use() { std::cout << "Resource used\n"; }
};

void run_smart_pointers_demo() {
    std::cout << "\n--- 2. Smart Pointers Demo ---\n";
    
    // Unique Pointer
    {
        std::unique_ptr<Resource> res = std::make_unique<Resource>();
        res->use();
    } // res goes out of scope here
    
    // Shared Pointer
    std::shared_ptr<Resource> sharedRes = std::make_shared<Resource>();
    {
        std::shared_ptr<Resource> sharedRes2 = sharedRes;
        std::cout << "Shared count: " << sharedRes.use_count() << "\n";
    }
    std::cout << "Shared count after scope: " << sharedRes.use_count() << "\n";
}
