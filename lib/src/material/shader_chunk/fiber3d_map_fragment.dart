const String fiber3dMapFragment = r'''
#ifdef USE_MAP

	vec4 sampledDiffuseColor = texture2D( map, vMapUv );

	diffuseColor *= sampledDiffuseColor;

#endif
''';