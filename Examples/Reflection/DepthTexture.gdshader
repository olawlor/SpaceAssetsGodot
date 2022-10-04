shader_type spatial;
render_mode unshaded;

void fragment()
{
    float zw = texture(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	float z = 1.0/zw-1.0; // convert to camera depth
	z *= 100.0; // make a reasonable color
    ALBEDO = vec3(z,0,0); // fract(z*10.0)); 
}

