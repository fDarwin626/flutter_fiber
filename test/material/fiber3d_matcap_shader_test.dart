import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_matcap_shader.dart';

void main() {
  group('Fiber3DMatcapShader', () {
    test('vertex shader includes the requested version and real uniform names', () {
      final src = Fiber3DMatcapShader.vertex('300 es');
      expect(src, contains('#version 300 es'));
      expect(src, contains('uniform mat4 modelViewMatrix;'));
      expect(src, contains('uniform mat4 projectionMatrix;'));
      expect(src, contains('uniform mat3 normalMatrix;'));
    });

    test('fragment shader declares no light-related uniforms at all', () {
      final src = Fiber3DMatcapShader.fragment('300 es');
      expect(src, isNot(contains('ambientLightColor')));
      expect(src, isNot(contains('pointLights')));
      expect(src, isNot(contains('uniform mat4 viewMatrix')));
    });

    test('fragment shader derives a view-space normal-orientation UV, not lighting math', () {
      final src = Fiber3DMatcapShader.fragment('300 es');
      expect(src, contains('vec3 viewDir = normalize( vViewPosition );'));
      expect(
        src,
        contains(
          'vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;',
        ),
      );
    });

    test('falls back to the fixed gradient since USE_MATCAP is never defined', () {
      final src = Fiber3DMatcapShader.fragment('300 es');
      expect(
        src,
        contains(
          'vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );',
        ),
      );
    });

    test('all #include directives are resolved', () {
      final src = Fiber3DMatcapShader.fragment('300 es');
      expect(src, isNot(contains('#include')));
    });

    test('desktop version (150) is respected', () {
      final src = Fiber3DMatcapShader.fragment('150');
      expect(src.startsWith('#version 150'), isTrue);
    });
  });
}