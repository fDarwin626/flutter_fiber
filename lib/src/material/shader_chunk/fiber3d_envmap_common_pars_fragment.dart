/// envMap uniforms and the roughness-to-mip mapping used to sample a
/// PMREM-style prefiltered environment cube map.
///
/// Ported from three.js's `envmap_common_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), trimmed to the
/// `ENVMAP_TYPE_PMREM` branch only flutter_fiber has no other envMap
/// type. No `USE_ANISOTROPY` branch: nothing here needs it.
const String fiber3dEnvmapCommonParsFragment = r'''
#ifdef USE_ENVMAP

	uniform float envMapIntensity;
	uniform mat3 envMapRotation;
	uniform samplerCube envMap;

	#ifdef ENVMAP_TYPE_PMREM

		// Invert PMREMGenerator.lodToRoughness(). Matches Filament's perceptualRoughnessToLod().
		// https://github.com/google/filament/blob/main/shaders/src/surface_light_indirect.fs
		float roughnessToMip( const in float roughness ) {

			float r = clamp( roughness, 0.0, 1.0 );

			return ENVMAP_MAX_LOD * r * ( 2.0 - r );

		}

	#endif

#endif
''';