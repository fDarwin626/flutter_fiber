/// The Blinn-Phong material model: the `BlinnPhongMaterial` struct
/// (diffuse color, specular color, shininess, specular strength) and the
/// `RE_Direct`/`RE_IndirectDiffuse` entry points direct light gets both
/// a Lambert diffuse term and a Blinn-Phong specular term; indirect
/// (ambient) light is diffuse-only, same as Lambert.
///
/// Ported from three.js's `lights_phong_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged. Depends on
/// `common` (BRDF_Lambert), `bsdfs` (BRDF_BlinnPhong), and
/// `lights_pars_begin` (IncidentLight, ReflectedLight).
const String fiber3dLightsPhongParsFragment = r'''
varying vec3 vViewPosition;

struct BlinnPhongMaterial {

	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;

};

void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {

	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;

	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;

}

void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {

	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

}

#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong
''';