/// `getIBLIrradiance` (diffuse) and `getIBLRadiance` (specular) sampling
/// functions for a PMREM-style prefiltered environment cube map.
///
/// Ported from three.js's `envmap_physical_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), trimmed to the two functions
/// `lights_fragment_maps` actually calls for STANDARD/LAMBERT/PHONG:
/// no `USE_RETROREFLECTION`, no `USE_ANISOTROPY`, no clearcoat — none
/// of those are ported yet, matching fiber3d_lights_fragment_maps.dart.
///
/// Depends on `transformNormalByInverseViewMatrix`,
/// `transformDirectionByInverseViewMatrix` and `pow4`, all already in
/// <common>, and on `roughnessToMip` from
/// <envmap_common_pars_fragment>, included first.
const String fiber3dEnvmapPhysicalParsFragment = r'''
#ifdef USE_ENVMAP

	vec3 getIBLIrradiance( const in vec3 normal ) {

		#ifdef ENVMAP_TYPE_PMREM

			vec3 worldNormal = transformNormalByInverseViewMatrix( normal, viewMatrix );

			vec4 envMapColor = textureLod( envMap, envMapRotation * worldNormal, ENVMAP_MAX_LOD );

			return PI * envMapColor.rgb * envMapIntensity;

		#else

			return vec3( 0.0 );

		#endif

	}

	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {

		#ifdef ENVMAP_TYPE_PMREM

			vec3 reflectVec = reflect( - viewDir, normal );

			// Mixing the reflection with the normal is more accurate and keeps rough objects from gathering light from behind their tangent plane.
			reflectVec = normalize( mix( reflectVec, normal, pow4( roughness ) ) );

			reflectVec = transformDirectionByInverseViewMatrix( reflectVec, viewMatrix );

			vec4 envMapColor = textureLod( envMap, envMapRotation * reflectVec, roughnessToMip( roughness ) );

			return envMapColor.rgb * envMapIntensity;

		#else

			return vec3( 0.0 );

		#endif

	}

#endif
''';