shader_type spatial;
render_mode unshaded;

void fragment()
{
    vec3 c = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
    ALBEDO = vec3(c.r,0.0,0.0);
}

