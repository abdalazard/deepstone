shader_type canvas_item;

uniform vec4 helmet_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 armor_color  : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 boots_color  : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 pickaxe_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.05) {
		COLOR = vec4(0.0);
		return;
	}

	float y = UV.y;
	float x = UV.x;

	// Zonas verticais do personagem
	vec3 zone_color;
	if (y < 0.30) {
		// Cabeça → capacete
		zone_color = helmet_color.rgb;
	} else if (y < 0.72) {
		// Corpo → traje; lado direito (mão com picareta) recebe leve toque da picareta
		float pick_blend = clamp((x - 0.60) / 0.40, 0.0, 1.0) * 0.45;
		zone_color = mix(armor_color.rgb, pickaxe_color.rgb, pick_blend);
	} else {
		// Pés → botas
		zone_color = boots_color.rgb;
	}

	// Multiplicar mantendo os detalhes do sprite original
	// Fator 1.6 para cores ficarem vivas sem estourar pixels escuros demais
	vec3 tinted = tex.rgb * zone_color * 1.6;
	COLOR = vec4(clamp(tinted, 0.0, 1.0), tex.a);
}
