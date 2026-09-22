/// Writes the normalized view-space normal (and tangent frame) into the
/// varyings declared by `normal_pars_vertex`, unless flat shaded.
///
/// Ported from three.js's `normal_vertex.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged. Consumes
/// `transformedNormal` (and `transformedTangent`) from
/// `defaultnormal_vertex`.
const String fiber3dNormalVertex = r'''
#ifndef FLAT_SHADED // normal is computed with derivatives when FLAT_SHADED

	vNormal = normalize( transformedNormal );

	#ifdef USE_TANGENT

		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );

		#ifdef FLIP_SIDED

			vBitangent = - vBitangent;

		#endif

	#endif

#endif
''';