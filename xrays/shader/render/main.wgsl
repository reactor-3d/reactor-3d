#import sampling::SamplingParams
#import tonemap

@group(0) @binding(0) var<uniform> vertex_uniforms: VertexUniforms;

struct VertexUniforms {
    view_proj_matrix: mat4x4<f32>,
    model_matrix: mat4x4<f32>,
}

struct VertexInput {
    @location(0) position: vec2<f32>,
    @location(1) tex_coords: vec2<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
}

@vertex
fn vs_main(model: VertexInput) -> VertexOutput {
    return VertexOutput(
        vertex_uniforms.view_proj_matrix * vertex_uniforms.model_matrix * vec4<f32>(model.position, 0.0, 1.0),
        model.tex_coords
    );
}

@group(1) @binding(0) var<uniform> frame_data: vec4<u32>;
@group(1) @binding(1) var<storage, read_write> image_buffer: array<array<f32, 3>>;

@group(2) @binding(0) var<uniform> sampling_params: SamplingParams;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let u = in.tex_coords.x;
    let v = in.tex_coords.y;

    let image_width = frame_data.x;
    let image_height = frame_data.y;

    let x = min(u32(u * f32(image_width)), image_width - 1u);
    let y = min(u32(v * f32(image_height)), image_height - 1u);
    let idx = image_width * y + x;

    let inv_n = 1f / f32(sampling_params.accumulated_samples_per_pixel);
    let pixel = vec3(image_buffer[idx][0], image_buffer[idx][1], image_buffer[idx][2]);

    return vec4(
        tonemap::uncharted2(inv_n * pixel),
        1f
    );
}
