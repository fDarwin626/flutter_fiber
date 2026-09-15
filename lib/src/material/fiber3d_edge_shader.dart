class Fiber3DEdgeShader {
  static String vertex(String version) => """#version $version
#define attribute in
#define varying out

attribute vec3 a_Position;

uniform mat4 u_ModelMatrix;
uniform mat4 u_ViewMatrix;
uniform mat4 u_ProjectionMatrix;

void main() {
    gl_Position = u_ProjectionMatrix * u_ViewMatrix * u_ModelMatrix * vec4(a_Position, 1.0);
}
""";

  static String fragment(String version) => """#version $version
precision highp float;
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor

uniform vec3 u_EdgeColor;

void main() {
    gl_FragColor = vec4(u_EdgeColor, 1.0);
}
""";
}