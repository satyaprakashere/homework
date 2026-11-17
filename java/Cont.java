import jdk.internal.vm.Continuation;
import jdk.internal.vm.ContinuationScope;

void main(String[] args) {
	var cont = getContinuation();
	
	cont.run(); IO.println("Doing something else");
	cont.run(); IO.println("Doing something else again");
	cont.run();
}

Continuation getContinuation() {
	var scope = new ContinuationScope("Demo!!");
	
	var cont = new Continuation(scope, () -> {
		IO.println("A"); Continuation.yield(scope);
		IO.println("B"); Continuation.yield(scope);
		IO.println("C");
	});
	
	return cont;
}
