/// The Lambert material model: the `LambertMaterial` struct (diffuse
/// color plus a specular-strength placeholder) and the `RE_Direct`/
/// `RE_IndirectDiffuse` entry points for pure Lambertian diffuse
/// lighting — no specular term at all.
///
/// Ported from three.js's `lights_lambert_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged. Depends on
/// `common` (BRDF_Lambert) and `lights_pars_begin` (IncidentLight,
/// ReflectedLight).
const String fiber3dLightsLambertParsFragment = r'''
varying vec3 vViewPosition;

struct LambertMaterial {

	vec3 diffuseColor;
	float specularStrength;

};

void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {

	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;

	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

}

void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {

	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

}

#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert
''';