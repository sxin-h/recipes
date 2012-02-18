-- Quad.VS

in vec2 Position;
in vec2 TexCoord;
out vec2 vTexCoord;

void main()
{
    vTexCoord = TexCoord;
    gl_Position = vec4(Position, 0, 1);
}

-- Quad.FS

in vec2 vTexCoord;
out vec4 FragColor;
uniform sampler2D Sampler;

void main()
{
    FragColor = texture(Sampler, vTexCoord);
}

-- VS

in vec4 Position;
out vec3 vPosition;
out int vId;

uniform mat4 Projection;
uniform mat4 Modelview;
uniform mat4 ViewMatrix;
uniform mat4 ModelMatrix;

void main()
{
    vPosition = Position.xyz;
    vId = gl_VertexID;
    gl_Position = Projection * Modelview * Position;
}

-- Lit.VS

in vec4 Position;
in vec3 Normal;

out vec3 vPosition;
out vec3 vNormal;

uniform mat4 Projection;
uniform mat4 Modelview;
uniform mat4 ViewMatrix;
uniform mat4 ModelMatrix;
uniform mat3 NormalMatrix;

void main()
{
    vPosition = Position.xyz;
    gl_Position = Projection * Modelview * Position;
    vNormal = NormalMatrix * Normal;
}

-- Lit.FS

in vec3 vNormal;
out vec4 FragColor;

uniform vec3 LightPosition = vec3(0.25, 0.25, 1.0);
uniform vec3 AmbientMaterial = vec3(0.04, 0.04, 0.04);
uniform vec3 SpecularMaterial = vec3(2.5, 2.5, 2.5);
uniform vec3 FrontMaterial = vec3(0.75, 0.75, 0.5);
uniform vec3 BackMaterial = vec3(0.5, 0.5, 0.75);
uniform float Shininess = 50;

void main()
{
    vec3 N = normalize(vNormal);
    if (gl_FrontFacing)
       N = -N;

    vec3 L = normalize(LightPosition);
    vec3 Eye = vec3(0, 0, 1);
    vec3 H = normalize(L + Eye);
    
    float df = max(0.0, dot(N, L));
    float sf = abs(dot(N,H)); // max(0.0, dot(N, H));
    sf = pow(sf, Shininess);

    vec3 color = gl_FrontFacing ? FrontMaterial : BackMaterial;
    vec3 lighting = AmbientMaterial + df * color;
//    if (gl_FrontFacing)
        lighting += sf * SpecularMaterial;

    FragColor = vec4(lighting, 1);
}

----------------------------------
  ____                _  _        
 / ___|  _ __   _ __ (_)| |_  ___ 
 \___ \ | '_ \ | '__|| || __|/ _ \
  ___) || |_) || |   | || |_|  __/
 |____/ | .__/ |_|   |_| \__|\___|
        |_|                       
-----------------------------------

-- Sprite.GS

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;
uniform bool Nailboard;
uniform vec2 SpriteSize;
in int vId[1];
flat out int gId;
out vec2 gCenterCoord;
uniform vec2 HalfViewport;
uniform vec2 InverseViewport;

vec2 toFragCoord(vec4 v)
{
    return HalfViewport * (1.0 + v.xy / v.w);
}

void main()
{
    vec4 P = gl_in[0].gl_Position;
    vec4 U = vec4(SpriteSize.x, 0, 0, 0) * InverseViewport.x;
    vec4 V = vec4(0, SpriteSize.y, 0, 0) * InverseViewport.y;
    gId = vId[0];
    gCenterCoord = toFragCoord(P);

    P.z = 0;
    P.xy /= P.w;
    P.w = 1;

    gl_Position = P - U - V; EmitVertex();
    gl_Position = P + U - V; EmitVertex();
    gl_Position = P - U + V; EmitVertex();
    gl_Position = P + U + V; EmitVertex();
    EndPrimitive();
}

-- Sprite.FS

flat in int gId;
out vec4 FragColor;
in vec2 gCenterCoord;
uniform bool Nailboard;
uniform vec2 SpriteSize;

vec3 colorFromIndex(int i)
{
    int r = i & 1;
    int g = i & 2;
    int b = i & 4;
    float x = (r == 0) ? 1.0 : 0.0;
    float y = (g == 0) ? 1.0 : 0.0;
    float z = (b == 0) ? 1.0 : 0.0;
    return vec3(x, y, z);
}

void main()
{
    float L = distance(gl_FragCoord.xy, gCenterCoord);
    float D = 2.0 * L / SpriteSize.x;
    if (Nailboard) {

        // Draw a billboard with cone-shaped depth
        FragColor.rgb = colorFromIndex(gId);
        FragColor.rgb *= 1 - D;
        FragColor.a = 1;
        gl_FragDepth = D;

    } else {

        // Draw a circular mouse cursor
        float t = 0.125;     // Border thickness
        float r = 0.75;      // Inner radius
        float w = fwidth(D); // Antialiasing constant
        if (D < r - t) {
            float A = 1.0 - smoothstep(r-t-w, r-t, D);
            FragColor = vec4(A, A, A, 1);
        } else if (D < r + t) {
            FragColor = vec4(0, 0, 0, 1);
        } else {
            float A = 1.0 - smoothstep(r+t, r+t+w, D);
            FragColor = vec4(0, 0, 0, A);
        }
    }
}