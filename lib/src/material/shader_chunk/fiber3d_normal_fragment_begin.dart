/// Builds the view-space surface `normal` (from the interpolated varying, or
/// from screen-space derivatives when FLAT_SHADED), flips it for back faces
/// when DOUBLE_SIDED, builds the tangent frames for normal-mapped and
/// anisotropic materials, and keeps `nonPerturbedNormal` for later use.
///
/// Ported from three.js's `normal_fragment_begin.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged. The tangent-frame
/// blocks call `getTangentFrame` (from `normalmap_pars_fragment`) and are
/// inactive until normal maps, clearcoat normal maps or anisotropy are
/// enabled. flutter_fiber's canvas bakes flat shading into per-triangle
/// vertex normals, so FLAT_SHADED is not defined.
const String fiber3dNormalFragmentBegin = r'''
float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;

#ifdef FLAT_SHADED

	vec3 fdx = dFdx( vViewPosition );
	vec3 fdy = dFdy( vViewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );

#else

	vec3 normal = normalize( vNormal );

	#ifdef DOUBLE_SIDED

		normal *= faceDirection;

	#endif

#endif

#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )

	#ifdef USE_TANGENT

		mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );

	#else

		mat3 tbn = getTangentFrame( - vViewPosition, normal,
		#if defined( USE_NORMALMAP )
			vNormalMapUv
		#elif defined( USE_CLEARCOAT_NORMALMAP )
			vClearcoatNormalMapUv
		#else
			vUv
		#endif
		);

	#endif

	#ifdef DOUBLE_SIDED

		tbn[0] *= faceDirection;
		tbn[1] *= faceDirection;

	#endif

#endif

#ifdef USE_CLEARCOAT_NORMALMAP

	#ifdef USE_TANGENT

		mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );

	#else

		mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );

	#endif

	#ifdef DOUBLE_SIDED

		tbn2[0] *= faceDirection;
		tbn2[1] *= faceDirection;

	#endif

#endif

// non perturbed normal for clearcoat among others

vec3 nonPerturbedNormal = normal;

''';