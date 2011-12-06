#version 120

uniform sampler2D texture0; // diffuse
uniform sampler2D texture1; // normal
uniform sampler2D texture3; // wreck

uniform float hasBump;
uniform float hasWreck;
uniform float hasXlpha;
uniform float showDiffuse;
uniform float showLighting;

//uniform vec3 sunambient;
//uniform vec3 sundiffuse;

varying vec2 uv;
varying vec3 norm;
varying vec3 sunvec;
varying vec3 eyesurfvec;         // eye to surface vector
varying vec4 boneinfo;

void main()
{
 //// temp: pass as uniforms
 vec3 sunambient = vec3(0.3,0.3,0.3);
 vec3 sundiffuse = vec3(0.7,0.7,0.7);
 vec3 sunspecular = sundiffuse;
 //// temp
 
 // base
 vec4 frag = vec4(1.0, 1.0, 1.0, 1.0);
 vec3 spec = vec3(1.0, 1.0, 1.0);
 
 // textures
 vec4 colormap = texture2D(texture0, uv);
 vec4 normalmap = texture2D(texture1, uv);
 vec4 wreckmap = texture2D(texture3, uv);
 
 // diffuse
 if (showDiffuse > 0.5) {
  frag *= colormap;
 } else {
  frag.rgb *= 0.75;
  frag.a = colormap.a;
 }
 
 // wreck map
 if (hasWreck > 0.5) {
  if (showDiffuse > 0.5) {
   frag.rgb *= wreckmap.rgb;
  }
  spec *= wreckmap.rgb;
 }
 
 // normal
 vec3 n;
 if (hasBump > 0.5) {
  // normal map
  n = normalize(normalmap.rgb * 2.0 - 1.0);
 } else {
  // vertex normal
  n = normalize(norm);
 }
 
 // specular
 if (hasXlpha > 0.5) {
  if (hasBump > 0.5) {
   spec *= normalmap.a;
  }
 } else {
  spec *= colormap.a;
 }
 
 // lighting
 if (showLighting > 0.5) {
  float NdotL = dot(n,normalize(-sunvec));
  frag.rgb *= sunambient.rgb + sundiffuse.rgb * max(NdotL,0.0);
  
  // normalize eye to surface vector
  vec3 eyevec = normalize(eyesurfvec);
  
  // specular
  if (NdotL > 0.0) { // todo: skip if shade==0
   
   // get half vector
   vec3 hv = normalize( -sunvec + eyevec );
   
   // compute specular amount
   float NdotHV = max(dot(n,hv),0.0);
   spec *= pow(NdotHV,100.0);
   
   // apply specular
   frag.rgb += sunspecular * spec;
  }
 }
 
 // output
 gl_FragColor = frag;
 //gl_FragColor = vec4(1.0, 0.1, 0.1, 1.0);
 //gl_FragColor = vec4(n,1.0);
 //gl_FragColor = wreckmap;
 //gl_FragColor = vec4(sunvec,1.0);
 //gl_FragColor = vec4(boneid*10.0);
 //gl_FragColor = boneinfo * 10.0;
 //gl_FragColor.rgb = vec3(hasXlpha);
}
