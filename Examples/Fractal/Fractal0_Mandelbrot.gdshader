/*
Mandelbrot Set shader

Dr. Orion Lawlor, lawlor@alaska.edu, 2022-10-25 (Public Domain)
*/
shader_type spatial;
render_mode unshaded;

void fragment() {
	vec3 world=(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Complex numbers: r is the real part, i is the imaginary part
	float cr=world.x, ci=world.y; // XY coordinates -> location in the fractal
	float zr=cr, zi=ci;  
	int iter=0;
	const int max_iter=1000;
	for (int i=0;i<max_iter;i++)
	{
		if (zr*zr + zi*zi > 4.0) break; //<- large z always blows up
		float nr = zr*zr - zi*zi + cr; // real
		float ni = 2.0*zr*zi + ci; // imaginary
		zr=nr; zi=ni;
		iter = i;
	}
	
	ALBEDO.rgb=vec3(zr/4.0,zi/4.0,float(iter)/float(max_iter));
}

