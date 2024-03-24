shader_type spatial;
render_mode unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

void fragment()
{
    float zw = texture(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	float z = 1.0/zw-1.0; // convert to camera depth
	z *= 100.0; // make a reasonable color
    ALBEDO = vec3(clamp(z,0.0,1.0),0,0); // fract(z*10.0)); 
}

