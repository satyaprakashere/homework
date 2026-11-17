module com.vedmata.webgpu {
    requires javafx.controls;
    requires javafx.fxml;


    opens com.vedmata.webgpu to javafx.fxml;
    exports com.vedmata.webgpu;
}