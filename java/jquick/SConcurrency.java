//import module java.util.concurrent;

void main() {
  
}

void testStructuralScope() throws InterruptedException {
  try (var scope = StructuredTaskScope.open()) {
    scope.join();
  }
}