extern number iTime;
extern vec2 iResolution;
extern number u_camAngleX;
extern number u_camAngleY;
extern sampler2D iChannel0;

const float NUM_RAYS = 13.0;

const int VOLUMETRIC_STEPS = 19;
const int MAX_ITER = 35;
const float FAR_DIST = 6.0;

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}

float noise_1d( in float x ){return texture2D(iChannel0, vec2(x*.01,1.0)).x;}

float hash( float n ){return fract(sin(n)*4112.1238);}


float noise_3d(in vec3 p)
{
	vec3 ip = floor(p);
    vec3 fp = fract(p);
	fp = fp*fp*(3.0-2.0*fp);

	vec2 tap = (ip.xy+vec2(37.0,17.0)*ip.z) + fp.xy;

	vec2 rg = texture2D( iChannel0, (tap + 0.5)/256.0 ).yx;
	return mix(rg.x, rg.y, fp.z);
}

mat3 m3 = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

float flow(in vec3 p, in float t_param)
{
	float z=2.0;
	float rz = 0.0;
	vec3 bp = p;
	for (float i= 1.0; i < 5.0; i++ )
	{
		p += (iTime*1.1)*.1;
		rz+= (sin(noise_3d(p+t_param*0.8)*6.0)*0.5+0.5) /z;
		p = mix(bp,p,0.6);
		z *= 2.0;
		p *= 2.01;
        p*= m3;
	}
	return rz;
}


float sins(in float x)
{
 	float rz = 0.0;
    float z = 2.0;
    for (float i= 0.0; i < 3.0; i++ )
	{
        rz += abs(fract(x*1.4)-0.5)/z;
        x *= 1.3;
        z *= 1.15;
        x -= (iTime*1.1)*.65*z;
    }
    return rz;
}

float segm( vec3 p, vec3 a, vec3 b)
{
    vec3 pa = p - a;
	vec3 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h )*.5;
}


vec3 path(in float i, in float d)
{
    vec3 en = vec3(0.0,0.0,1.0);
    float sns2 = sins(d+i*0.5)*0.22;
    float sns = sins(d+i*0.6)*0.21;
    en.xz *= mm2((hash(i*10.569)-.5)*6.2+sns2);
    en.xy *= mm2((hash(i*4.732)-.5)*6.2+sns);
    return en;
}


vec2 map(vec3 p, float i)
{
	float lp = length(p);
    vec3 bg = vec3(0.0);
    vec3 en = path(i,lp);

    float ins = smoothstep(0.11,.46,lp);
    float outs = .15+smoothstep(.0,.15,abs(lp-1.0));
    p *= ins*outs;
    float id_val = ins*outs;

    float rz = segm(p, bg, en)-0.011;
    return vec2(rz,id_val);
}


float march(in vec3 ro, in vec3 rd, in float startf, in float maxd, in float j)
{
	float precis = 0.001;
    float h=0.5;
    float d = startf;
    for( int i=0; i<MAX_ITER; i++ )
    {
        if( abs(h)<precis||d>maxd ) break;
        d += h*1.2;
	    float res = map(ro+rd*d, j).x;
        h = res;
    }
	return d;
}

vec3 vmarch(in vec3 ro, in vec3 rd, in float j, in vec3 orig)
{
    vec3 p = ro;
    vec2 r = vec2(0.0);
    vec3 sum = vec3(0.0);

    for( int i=0; i<VOLUMETRIC_STEPS; i++ )
    {
        r = map(p,j);
        p += rd*0.03;
        float lp = length(p);

        vec3 col_sample = sin(vec3(1.05,2.5,1.52)*3.94+r.y)*.85+0.4; 
        col_sample.rgb *= smoothstep(.0,.015,-r.x);
        col_sample *= smoothstep(0.04,.2,abs(lp-1.1));
        col_sample *= smoothstep(0.1,.34,lp);

        sum += abs(col_sample)*5.0 * (1.2-noise_1d(lp*2.0+j*13.0+(iTime*1.1)*5.0)*1.1) / (log(distance(p,orig)-2.0)+.75);
    }
    return sum;
}


vec2 iSphere2(in vec3 ro, in vec3 rd)
{
    vec3 oc = ro;
    float b = dot(oc, rd);
    float c = dot(oc,oc) - 1.0;
    float h = b*b - c;
    if(h <0.0) return vec2(-1.0);
    else return vec2((-b - sqrt(h)), (-b + sqrt(h)));
}

vec3 rotate_around_axis(vec3 v, vec3 k, float theta) {
    float cos_theta = cos(theta);
    float sin_theta = sin(theta);
    return v * cos_theta + cross(k, v) * sin_theta + k * dot(k, v) * (1.0 - cos_theta);
}

vec4 effect(vec4 pixel_color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec2 p_norm = screen_coords.xy/iResolution.xy-0.5;
	p_norm.x*=iResolution.x/iResolution.y;

	vec3 ro = vec3(0.0,0.0,5.0);
    vec3 rd = normalize(vec3(p_norm*0.5,-1.5));
    float yaw_angle = u_camAngleX + sin(iTime * 0.21);
    float pitch_angle = u_camAngleY + sin(iTime * 0.23);
    
    mat2 m_yaw = mm2(yaw_angle);

    vec3 ro_yawed;
    ro_yawed.xz = m_yaw * ro.xz;
    ro_yawed.y  = ro.y;

    vec3 rd_yawed;
    rd_yawed.xz = m_yaw * rd.xz;
    rd_yawed.y  = rd.y;
    rd_yawed = normalize(rd_yawed); 
    vec3 pitch_axis;
    pitch_axis = normalize(vec3(cos(yaw_angle), 0.0, sin(yaw_angle))); 

    
    ro = rotate_around_axis(ro_yawed, pitch_axis, pitch_angle);
    rd = rotate_around_axis(rd_yawed, pitch_axis, pitch_angle);
    rd = normalize(rd); 

    vec3 bro = ro; 
    vec3 brd = rd; 

    vec3 col = vec3(0.0125,0.0,0.025);

    for (float j = 1.0; j < NUM_RAYS + 1.0; j++)
    {
        vec3 loop_ro = bro;
        vec3 loop_rd = brd;

        mat2 mm_loop = mm2(((iTime*1.1)*0.1+((j+1.0)*5.1))*j*0.25);
        loop_ro.xy *= mm_loop; loop_rd.xy *= mm_loop;
        loop_ro.xz *= mm_loop; loop_rd.xz *= mm_loop;

        float rz = march(loop_ro, loop_rd, 2.5, FAR_DIST, j);
		if ( rz >= FAR_DIST) continue;

    	vec3 pos = loop_ro + rz * loop_rd; 
    	vec3 v_col = vmarch(pos, loop_rd, j, bro); 

        
        float dist_to_cam = length(pos - bro); 

        
        float atten_start_dist = 4.0;      
        float atten_end_dist = 6.0;        
        float min_brightness_factor = 0.01; 
        
        float factor = smoothstep(atten_end_dist, atten_start_dist, dist_to_cam);

        
        float attenuation_multiplier = mix(min_brightness_factor, 1.0, factor);

        v_col *= attenuation_multiplier; 
        

    	col = max(col, v_col); 
    }
    
    
    vec2 sph = iSphere2(ro,rd); 

    if (sph.x > 0.0)
    {
        vec3 pos_hit = ro+rd*sph.x; 
        vec3 pos2_hit = ro+rd*sph.y;
        
        vec3 rf = reflect( rd, pos_hit );
        vec3 rf2 = reflect( rd, pos2_hit );

        float nz = (-log(abs(flow(rf*1.2+rf*rf, (iTime*1.1)) - 0.01)));
        float nz2 = (-log(abs(flow(rf2*1.2+rf2*rf2, -(iTime*1.1)) - 0.01)));
        col += (0.1*nz*nz* vec3(0.12,0.12,.5) + 0.15*nz2*nz2*vec3(0.55,0.2,.55))*0.8;
    }

	return vec4(col*0.5, 1.0);
}