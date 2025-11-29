// Define a scoped value
ScopedValue<String> USER_CONTEXT = ScopedValue.newInstance();

void main() {
    // Bind value and run code within that scope
    ScopedValue.where(USER_CONTEXT, "alice").run(() -> {
        // User context "alice" available in this block
        // Read the current scoped value
        String currentName = USER_CONTEXT.get(); // "duke1"
        IO.println(currentName);
    });

}


void methodThatNeedsUserContext() {
    
}