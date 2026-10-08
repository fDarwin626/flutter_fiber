const String fiber3dMapFragment = r'''
#ifdef USE_MAP

	vec4 sampledDiffuseColor = texture2D( map, vMapUv );

	#ifdef DECODE_MAP_SRGB
		sampledDiffuseColor.rgb = mix(
			pow( sampledDiffuseColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ),
			sampledDiffuseColor.rgb * 0.0773993808,
			vec3( lessThanEqual( sampledDiffuseColor.rgb, vec3( 0.04045 ) ) )
		);
	#endif

	diffuseColor *= sampledDiffuseColor;
#endif
''';