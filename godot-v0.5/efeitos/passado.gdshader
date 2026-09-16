shader_type canvas_item;
// O tratamento fica apenas no cenário; não reduz a resolução da interface.
uniform float intensidade : hint_range(0.0, 1.0) = 0.45;
uniform bool movimento = true;
void fragment() {
	vec2 pixel = floor(UV * vec2(480.0, 720.0));
	vec2 uv = mix(UV, pixel / vec2(480.0, 720.0), intensidade * 0.3);
	vec4 origem = texture(TEXTURE, uv);
	float ruido = fract(sin(dot(pixel, vec2(12.9898,78.233))) * 43758.5453) - 0.5;
	vec3 cor = mix(origem.rgb, floor(origem.rgb * 28.0 + ruido * 0.35) / 28.0, intensidade);
	float nevoa = movimento ? sin(UV.x * 8.0 + TIME * 0.12) * sin(UV.y * 7.0 - TIME * 0.08) : 0.0;
	cor += vec3(0.03, 0.05, 0.07) * max(nevoa, 0.0) * intensidade;
	COLOR = vec4(max(cor, vec3(0.0)), origem.a);
}
