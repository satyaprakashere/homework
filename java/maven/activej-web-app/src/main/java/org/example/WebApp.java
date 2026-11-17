package org.example;

import io.activej.http.AsyncServlet;
import io.activej.http.HttpResponse;
import io.activej.inject.annotation.Provides;
import io.activej.launcher.Launcher;
import io.activej.launchers.http.HttpServerLauncher;

public class WebApp extends HttpServerLauncher {

    @Provides
    AsyncServlet servlet() {
        return request -> HttpResponse.ok200()
                .withPlainText("Hello, World!")
                .toPromise();
    }

    public static void main(String[] args) throws Exception {
        Launcher launcher = new WebApp();
        launcher.launch(args);
    }
}
