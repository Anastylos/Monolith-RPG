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

vec2 tri2(vec2 p) {
    return vec2(tri(p.x) + tri(p.y), tri(p.y + tri(p.x)));
}

float triNoise2d(vec2 p, float spd) {
    float z = 1.8;
    float z2 = 2.5;
    float rz = 0.;
    p *= mm2(p.x * 0.06);
    vec2 bp = p;
    for (float i = 0.; i < 5.; i++) {
        vec2 dg = tri2(bp * 1.85) * 0.75;
        dg *= mm2(TIME * spd);
        p -= dg / z2;

        bp *= 1.3;
        z2 *= .45;
        z *= .42;
        p *= 1.21 + (rz - 1.0) * .02;

        rz += tri(p.x + tri(p.y)) * z;
        // CORRECCIÓN: Multiplicación por -1.0 para invertir la matriz
        p *= (m2 * -1.0);
    }
    return clamp(1. / pow(rz * 29., 1.3), 0., .55);
}

float hash21(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}


vec4 aurora(vec3 ro, vec3 rd, vec2 fragCoord) {
    vec4 col = vec4(0);
    vec4 avgCol = vec4(0);

    for(float i=0.; i<50.; i++) {
        float of = 0.006 * hash21(fragCoord) * smoothstep(0., 15., i);
        float pt = ((.8 + pow(i, 1.4) * .002) - ro.y) / (rd.y * 2. + 0.4);
        pt -= of;
        vec3 bpos = ro + pt * rd;
        vec2 p = bpos.zx;
        float rzt = triNoise2d(p, 0.06);
        vec4 col2 = vec4(0, 0, 0, rzt);

        vec3 color_variation = (sin(1. - vec3(2.15, -0.5, 1.2) + i * 0.043) * 0.5 + 0.5);
        col2.rgb = aurora_color.rgb * color_variation * rzt;

        avgCol = mix(avgCol, col2, 0.5);
        col += avgCol * exp2(-i * 0.065 - 2.5) * smoothstep(0., 5., i);
    }
    col *= (clamp(rd.y * 15. + 0.4, 0., 1.));
    return col * aurora_intensity;
}


vec3 nmzHash33(vec3 q) {
    uvec3 p = uvec3(ivec3(q));
    p = p * uvec3(374761393U, 1103515245U, 668265263U) + p.zxy + p.yzx;
    p = p.yzx * (p.zxy ^ (p >> 3U));
    return vec3(p ^ (p >> 16U)) * (1.0 / 4294967295.0);
}

vec3 stars(vec3 p, vec2 res) {
    vec3 c = vec3(0.);
    float res_val = res.x;
    for (float i=0.; i<4.; i++) {
        vec3 q = fract(p * (0.15 * res_val)) - 0.5;
        vec3 id = floor(p * (0.15 * res_val));
        vec2 rn = nmzHash33(id).xy;
        float c2 = 1. - smoothstep(0., 0.6, length(q));
        c2 *= step(rn.x, 0.0005 + i * i * 0.001);
        c += c2 * (mix(vec3(1.0, 0.49, 0.1), vec3(0.75, 0.9, 1.0), rn.y) * 0.1 + 0.9);
        p *= 1.3;
    }
    return c * c * star_brightness;
}

vec3 bg(vec3 rd) {
    float sd = dot(normalize(vec3(-0.5, -0.6, 0.9)), rd) * 0.5 + 0.5;
    sd = pow(sd, 5.);
    vec3 col = mix(background_color1.rgb, background_color2.rgb, sd);
    return col * 0.63;
}


void fragment() {
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;

    vec3 ro = vec3(0, 0, -6.7);
    vec2 uv_sphere = FRAGCOORD.xy / iResolution.xy;
    float theta = (uv_sphere.y) * PI;
    float phi = (uv_sphere.x - 0.5) * 2.0 * PI;
    vec3 rd = vec3(sin(theta) * sin(phi), sin(theta) * cos(phi), cos(theta));

    float time_rot = TIME * 0.05;
    rd.yz *= mm2(0.4);
    rd.xz *= mm2(sin(time_rot) * 0.2);

    vec3 col = vec3(0.);
    float fade = smoothstep(0., 0.01, abs(rd.y)) * 0.1 + 0.9;

    col = bg(rd) * fade;

    if (rd.y > 0.) {
        vec4 aur = smoothstep(0., 1.5, aurora(ro, rd, FRAGCOORD.xy)) * fade;
        col += stars(rd, iResolution);
        col = col * (1. - aur.a) + aur.rgb;
    } else {
        // Reflejos
        vec3 rrd = rd;
        rrd.y = abs(rrd.y);
        col = bg(rrd) * fade * 0.6;
        vec4 aur = smoothstep(0.0, 2.5, aurora(ro, rrd, FRAGCOORD.xy));
        col += stars(rrd, iResolution) * 0.1;
        col = col * (1. - aur.a) + aur.rgb;

        vec3 pos = ro + ((0.5 - ro.y) / rrd.y) * rrd;
        float nz2 = triNoise2d(pos.xz * vec2(0.5, 0.7), 0.);
        col += mix(vec3(0.2, 0.25, 0.5) * 0.08, vec3(0.3, 0.3, 0.5) * 0.7, nz2 * 0.4);
    }

    COLOR = vec4(col, 1.0);
}