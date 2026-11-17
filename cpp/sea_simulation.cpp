// sea_simulation.cpp

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <cmath>
#include <iostream>

// Vertex shader source
const char* vertexShaderSource = R"(
#version 330 core
layout(location = 0) in vec3 aPos;
out float waveHeight;
uniform float time;
void main()
{
    float wave = sin(aPos.x * 4.0 + time) * cos(aPos.z * 4.0 + time) * 0.2;
    waveHeight = wave;
    gl_Position = vec4(aPos.x, aPos.y + wave, aPos.z, 1.0);
}
)";

// Fragment shader source
const char* fragmentShaderSource = R"(
#version 330 core
in float waveHeight;
out vec4 FragColor;
void main()
{
    float blue = 0.5 + waveHeight;
    FragColor = vec4(0.0, 0.3 + waveHeight, blue, 1.0);
}
)";

// Create a grid mesh for the sea surface
void createSeaMesh(std::vector<float>& vertices, std::vector<unsigned int>& indices, int gridSize) {
    float size = 2.0f;
    float step = size / (gridSize - 1);
    for (int z = 0; z < gridSize; ++z) {
        for (int x = 0; x < gridSize; ++x) {
            float xpos = -1.0f + x * step;
            float zpos = -1.0f + z * step;
            vertices.push_back(xpos);
            vertices.push_back(0.0f);
            vertices.push_back(zpos);
        }
    }
    for (int z = 0; z < gridSize - 1; ++z) {
        for (int x = 0; x < gridSize - 1; ++x) {
            int i = z * gridSize + x;
            indices.push_back(i);
            indices.push_back(i + gridSize);
            indices.push_back(i + 1);

            indices.push_back(i + 1);
            indices.push_back(i + gridSize);
            indices.push_back(i + gridSize + 1);
        }
    }
}

GLuint compileShader(GLenum type, const char* src) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &src, nullptr);
    glCompileShader(shader);
    int success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char info[512];
        glGetShaderInfoLog(shader, 512, nullptr, info);
        std::cerr << "Shader compile error: " << info << std::endl;
    }
    return shader;
}

int main() {
    if (!glfwInit()) return -1;
    GLFWwindow* window = glfwCreateWindow(800, 600, "OpenGL Sea Simulation", nullptr, nullptr);
    if (!window) { glfwTerminate(); return -1; }
    glfwMakeContextCurrent(window);
    glewExperimental = GL_TRUE;
    if (glewInit() != GLEW_OK) { std::cerr << "GLEW error\n"; return -1; }

    // Compile shaders
    GLuint vs = compileShader(GL_VERTEX_SHADER, vertexShaderSource);
    GLuint fs = compileShader(GL_FRAGMENT_SHADER, fragmentShaderSource);
    GLuint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vs);
    glAttachShader(shaderProgram, fs);
    glLinkProgram(shaderProgram);
    glDeleteShader(vs);
    glDeleteShader(fs);

    // Create mesh
    std::vector<float> vertices;
    std::vector<unsigned int> indices;
    int gridSize = 100;
    createSeaMesh(vertices, indices, gridSize);

    GLuint VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), vertices.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(unsigned int), indices.data(), GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    glUseProgram(shaderProgram);

    while (!glfwWindowShouldClose(window)) {
        glClearColor(0.0f, 0.2f, 0.4f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        float timeValue = (float)glfwGetTime();
        int timeLoc = glGetUniformLocation(shaderProgram, "time");
        glUniform1f(timeLoc, timeValue);

        glBindVertexArray(VAO);
        glDrawElements(GL_TRIANGLES, indices.size(), GL_UNSIGNED_INT, 0);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteBuffers(1, &EBO);
    glDeleteProgram(shaderProgram);

    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}
