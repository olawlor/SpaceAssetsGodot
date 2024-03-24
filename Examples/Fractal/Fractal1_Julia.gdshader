/*
Julia Set shader

Dr. Orion Lawlor, lawlor@alaska.edu, 2022-10-25 (Public Domain)
*/
shader_type spatial;
render_mode unshaded;

void fragment() {
	vec3 world=(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Complex numbers: r is the real part, i is the imaginary part
	float cr=sin(0.1*TIME), ci=0.5; // constant = area of the Julia set
	float zr=world.x, zi=world.y; // XY coordinates -> starting value of iteration
	int iter=0;
	const int max_iter=100;
	for (int i=0;i<max_iter;i++)
	{
		if (zr*zr + zi*zi > 4.0) break; //<- large z always blows up
		float nr = zr*zr - zi*zi + cr; // real
		float ni = 2.0*zr*zi + ci; // imaginary
		zr=nr; zi=ni;
		iter=i;
	}
	
	ALBEDO.rgb=vec3(zr/4.0,zi/4.0,float(iter)/float(max_iter));
}

