shader_type canvas_item;

uniform vec4 aurora_color : source_color = vec4(0.84, 0.840, 0.90, 1.0); // Color principal de la aurora
uniform vec4 background_color1 : source_color = vec4(0.05, 0.1, 0.2, 1.0);
uniform vec4 background_color2 : source_color = vec4(0.1, 0.05, 0.2, 1.0);
uniform float aurora_intensity : hint_range(0.0, 5.0) = 1.8;
uniform float star_brightness : hint_range(0.0, 1.0) = 0.8;

#define PI 3.14159265358979323846264


mat2 mm2(float a) {
    float c = cos(a), s = sin(a);
    return mat2(vec2(c, s), vec2(-s, c));
}

const mat2 m2 = mat2(vec2(0.95534, 0.29552), vec2(-0.29552, 0.95534));

float tri(float x) {
    return clamp(abs(fract(x) - 0.5), 0.01, 0.49);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
