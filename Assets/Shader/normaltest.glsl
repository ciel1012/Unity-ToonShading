import lib-sampler.glsl

const float PI  = 3.141592653589793;
//: param auto world_eye_position
uniform vec3 camera_pos;

//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;

//: param auto channel_normal
uniform SamplerSparse normal_texture;
//: param auto texture_normal
uniform SamplerSparse base_normal_texture;
//: param auto normal_y_coeff
uniform float base_normal_y_coeff;

//: param auto channel_user0
uniform SamplerSparse user0_tex;


//: param custom {
//:   "default": false,
//:   "label": "expDirectX"
//: }
uniform bool expDirectX;

//: param custom {
//:   "default": true,
//:   "label": "showNormal"
//: }
uniform bool showNormal;

//: param custom {
//:   "default": false,
//:   "label": "exportInvertGamma"
//: }
uniform bool exportInvertGamma;

//: param custom {
//:  "default": 0.5,
//:   "min": 0.0,
//:   "max": 1.0,
//:   "label": "shadepos"
//: }
uniform float shadepos;

//: param custom {
//:   "default": 0.001,
//:   "min": 0.001,
//:   "max": 1.0,
//:   "label": "softness"
//: }
uniform float softness;

//: param custom {
//:   "default": 0.0,
//:   "min": -1.0,
//:   "max": 1.0,
//:   "label": "lightAngleW"
//: }
uniform float lightAngleW;

//: param custom {
//:   "default": 0.0,
//:   "min": -1.0,
//:   "max": 1.0,
//:   "label": "lightAngleH"
//: }
uniform float lightAngleH;

//: param custom {
//:   "default": false,
//:   "label": "lightFollowCamera"
//: }
uniform bool lightFollowCamera;

vec3 normalFade(vec3 normal,float attenuation)
{
 if (attenuation<1.0 && normal.z<1.0)
 {
   float phi = attenuation * acos(normal.z);
   normal.xy *= 1.0/sqrt(1.0-normal.z*normal.z) * sin(phi);
   normal.z = cos(phi);
 }

 return normal;
}

vec3 normalUnpack(vec4 normal_alpha, float y_coeff)
{
 if (normal_alpha.a == 0.0 || normal_alpha.xyz == vec3(0.0)) {
   return vec3(0.0, 0.0, 1.0);
 }

 vec3 normal = normal_alpha.xyz * 2.0 - vec3(1.0);
 normal.y *= y_coeff;
 normal = normalize(normal);

 return normal;
}

vec3 getWorldNormal(V2F inputs)
{
   vec3 worldNormal = normalUnpack(textureSparse(normal_texture, inputs.sparse_coord), -1);
   return worldNormal;
}

dvec3 tangentTransform(V2F inputs,vec3 worldNormal)
{
   dmat3 WorldNormalToTangentNormal = dmat3( inputs.tangent.x , inputs.bitangent.x , inputs.normal.x,
                                          inputs.tangent.y , inputs.bitangent.y , inputs.normal.y,
                                          inputs.tangent.z , inputs.bitangent.z , inputs.normal.z);
   dvec3 tangentNormal = (WorldNormalToTangentNormal) * worldNormal;

   return tangentNormal;
}

dvec3 worldTransform(V2F inputs,dvec3 tangentNormal)
{

   dmat3 TangentNormalToWorldNormal = dmat3( inputs.tangent.x , inputs.tangent.y , inputs.tangent.z,
                                          inputs.bitangent.x , inputs.bitangent.y , inputs.bitangent.z,
                                          inputs.normal.x , inputs.normal.y , inputs.normal.z);
   dvec3 worldNormal = (TangentNormalToWorldNormal) * tangentNormal;

   return worldNormal;
}

dvec3 vectorToColor(dvec3 Vector)
{
   dvec3 outColor = Vector/vec3(2.0)+vec3(0.5);//convertColor

   outColor.y = mix(outColor.y,1.0-outColor.y,expDirectX);

   outColor = mix(outColor,pow(vec3(outColor),vec3(2.2)),exportInvertGamma);

   return outColor;
}

vec3 toon(V2F inputs,dvec3 tangentNormal)
{
   vec3 L = lightFollowCamera ? normalize(camera_pos - inputs.position): vec3(0,0,1);
   mat3 Ry = mat3( cos(lightAngleW * PI),  0,  sin(lightAngleW * PI),
                   0,      1,   0,    
                 -1*sin(lightAngleW * PI), 0,  cos(lightAngleW * PI));

   mat3 Rx = mat3( 1,    0,      0,
                   0, cos(lightAngleH * PI), -1*sin(lightAngleH * PI),    
                   0, sin(lightAngleH * PI),  cos(lightAngleH * PI));

   L = Ry * Rx * L;//transform light vector

   vec3 V = normalize(camera_pos - inputs.position);

   vec3 baseColor = getBaseColor(basecolor_tex, inputs.sparse_coord).rgb;
   //vec3 shadeColor = textureSparse(user0_tex,  inputs.sparse_coord).rgb;
   vec3 shadeColor = getBaseColor(user0_tex,  inputs.sparse_coord).rgb;
   shadeColor = pow(shadeColor,vec3(2.2));

   //transformTangentNormalToWorldNormal
   dvec3 worldNormal = worldTransform(inputs,tangentNormal);

   double halfLambert = dot(worldNormal,L)*0.5+0.5;//halfLambert
   float lightArea = float(1.0 -( (halfLambert - shadepos + softness) / softness));
   lightArea = clamp( lightArea, 0.0, 1.0 );//clamping 0 to 1
   vec3 finalColor = mix(baseColor ,shadeColor ,lightArea); // Final Color

   return finalColor;
}

void shade(V2F inputs)
{
   vec3 worldNorm = getWorldNormal(inputs);
   dvec3 tangentNorm = tangentTransform(inputs,worldNorm);
   dvec3 tangentNorm_color = vectorToColor(tangentNorm);
   
   vec3 toon = toon(inputs,tangentNorm);

   vec3 outputColor = mix( toon,vec3(tangentNorm_color) ,showNormal);

   emissiveColorOutput(vec3(outputColor));
   alphaOutput(1.0);
}