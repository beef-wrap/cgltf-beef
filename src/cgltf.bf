/**
 * cgltf - a single-file glTF 2.0 parser written in C99.
 *
 * Version: 1.14
 *
 * Website: https://github.com/jkuhlmann/cgltf
 *
 * Distributed under the MIT License, see notice at the end of this file.
 *
 * Building:
 * Include this file where you need the struct and function
 * declarations. Have exactly one source file where you define
 * `CGLTF_IMPLEMENTATION` before including this file to get the
 * function definitions.
 *
 * Reference:
 * `cgltf_result cgltf_parse(const cgltf_options*, const void*,
 * cgltf_size, cgltf_data**)` parses both glTF and GLB data. If
 * this function returns `cgltf_result_success`, you have to call
 * `cgltf_free()` on the created `cgltf_data*` variable.
 * Note that contents of external files for buffers and images are not
 * automatically loaded. You'll need to read these files yourself using
 * URIs in the `cgltf_data` structure.
 *
 * `cgltf_options` is the struct passed to `cgltf_parse()` to control
 * parts of the parsing process. You can use it to force the file type
 * and provide memory allocation as well as file operation callbacks.
 * Should be zero-initialized to trigger default behavior.
 *
 * `cgltf_data` is the struct allocated and filled by `cgltf_parse()`.
 * It generally mirrors the glTF format as described by the spec (see
 * https://github.com/KhronosGroup/glTF/tree/master/specification/2.0).
 *
 * `void cgltf_free(cgltf_data*)` frees the allocated `cgltf_data`
 * variable.
 *
 * `cgltf_result cgltf_load_buffers(const cgltf_options*, cgltf_data*,
 * const char* gltf_path)` can be optionally called to open and read buffer
 * files using the `FILE*` APIs. The `gltf_path` argument is the path to
 * the original glTF file, which allows the parser to resolve the path to
 * buffer files.
 *
 * `cgltf_result cgltf_load_buffer_base64(const cgltf_options* options,
 * cgltf_size size, const char* base64, void** out_data)` decodes
 * base64-encoded data content. Used internally by `cgltf_load_buffers()`.
 * This is useful when decoding data URIs in images.
 *
 * `cgltf_result cgltf_parse_file(const cgltf_options* options, const
 * char* path, cgltf_data** out_data)` can be used to open the given
 * file using `FILE*` APIs and parse the data using `cgltf_parse()`.
 *
 * `cgltf_result cgltf_validate(cgltf_data*)` can be used to do additional
 * checks to make sure the parsed glTF data is valid.
 *
 * `cgltf_node_transform_local` converts the translation / rotation / scale properties of a node
 * into a mat4.
 *
 * `cgltf_node_transform_world` calls `cgltf_node_transform_local` on every ancestor in order
 * to compute the root-to-node transformation.
 *
 * `cgltf_accessor_unpack_floats` reads in the data from an accessor, applies sparse data (if any),
 * and converts them to floating point. Assumes that `cgltf_load_buffers` has already been called.
 * By passing null for the output pointer, users can find out how many floats are required in the
 * output buffer.
 *
 * `cgltf_accessor_unpack_indices` reads in the index data from an accessor. Assumes that
 * `cgltf_load_buffers` has already been called. By passing null for the output pointer, users can
 * find out how many indices are required in the output buffer. Returns 0 if the accessor is
 * sparse or if the output component size is less than the accessor's component size.
 *
 * `cgltf_num_components` is a tiny utility that tells you the dimensionality of
 * a certain accessor type. This can be used before `cgltf_accessor_unpack_floats` to help allocate
 * the necessary amount of memory. `cgltf_component_size` and `cgltf_calc_size` exist for
 * similar purposes.
 *
 * `cgltf_accessor_read_float` reads a certain element from a non-sparse accessor and converts it to
 * floating point, assuming that `cgltf_load_buffers` has already been called. The passed-in element
 * size is the number of floats in the output buffer, which should be in the range [1, 16]. Returns
 * false if the passed-in element_size is too small, or if the accessor is sparse.
 *
 * `cgltf_accessor_read_uint` is similar to its floating-point counterpart, but limited to reading
 * vector types and does not support matrix types. The passed-in element size is the number of uints
 * in the output buffer, which should be in the range [1, 4]. Returns false if the passed-in
 * element_size is too small, or if the accessor is sparse.
 *
 * `cgltf_accessor_read_index` is similar to its floating-point counterpart, but it returns size_t
 * and only works with single-component data types.
 *
 * `cgltf_copy_extras_json` allows users to retrieve the "extras" data that can be attached to many
 * glTF objects (which can be arbitrary JSON data). This is a legacy function, consider using
 * cgltf_extras::data directly instead. You can parse this data using your own JSON parser
 * or, if you've included the cgltf implementation using the integrated JSMN JSON parser.
 */

using System;
using System.Interop;

namespace cgltf;

public static class cgltf
{
	typealias size_t = uint;
	typealias char = char8;
	typealias cgltf_size = size_t;
	typealias cgltf_ssize = double;
	typealias cgltf_float = float;
	typealias cgltf_int = c_int;
	typealias cgltf_uint = c_uint;
	typealias cgltf_bool = c_int;

	public enum cgltf_file_type : c_int
	{
		cgltf_file_type_invalid,
		cgltf_file_type_gltf,
		cgltf_file_type_glb,
		cgltf_file_type_max_enum
	}

	public enum cgltf_result : c_int
	{
		cgltf_result_success,
		cgltf_result_data_too_short,
		cgltf_result_unknown_format,
		cgltf_result_invalid_json,
		cgltf_result_invalid_gltf,
		cgltf_result_invalid_options,
		cgltf_result_file_not_found,
		cgltf_result_io_error,
		cgltf_result_out_of_memory,
		cgltf_result_legacy_gltf,
		cgltf_result_max_enum
	}

	typealias AllocFunc = function void*(void* user, cgltf_size size);
	typealias FreeFunc = function void(void* user, void* ptr);

	[CRepr]
	public struct cgltf_memory_options
	{
		public AllocFunc alloc_fun;
		public FreeFunc free_func;
		public void* user_data;
	}

	typealias ReadFunc = function cgltf_result(cgltf_memory_options* memory_options, cgltf_file_options* file_options, char* path, cgltf_size* size, void** data);
	typealias ReleaseFunc = function void(cgltf_memory_options* memory_options, cgltf_file_options* file_options, void* data);

	[CRepr]
	public struct cgltf_file_options
	{
		public ReadFunc read;
		public ReleaseFunc release;
		public void* user_data;
	}

	[CRepr]
	public struct cgltf_options
	{
		public cgltf_file_type type; /* invalid == auto detect */
		public cgltf_size json_token_count; /* 0 == auto */
		public cgltf_memory_options memory;
		public cgltf_file_options file;
	}

	public enum cgltf_buffer_view_type : c_int
	{
		cgltf_buffer_view_type_invalid,
		cgltf_buffer_view_type_indices,
		cgltf_buffer_view_type_vertices,
		cgltf_buffer_view_type_max_enum
	}

	public enum cgltf_attribute_type : c_int
	{
		cgltf_attribute_type_invalid,
		cgltf_attribute_type_position,
		cgltf_attribute_type_normal,
		cgltf_attribute_type_tangent,
		cgltf_attribute_type_texcoord,
		cgltf_attribute_type_color,
		cgltf_attribute_type_joints,
		cgltf_attribute_type_weights,
		cgltf_attribute_type_custom,
		cgltf_attribute_type_max_enum
	}

	public enum cgltf_component_type : c_int
	{
		cgltf_component_type_invalid,
		cgltf_component_type_r_8, /* BYTE */
		cgltf_component_type_r_8u, /* UNSIGNED_BYTE */
		cgltf_component_type_r_16, /* SHORT */
		cgltf_component_type_r_16u, /* UNSIGNED_SHORT */
		cgltf_component_type_r_32u, /* UNSIGNED_INT */
		cgltf_component_type_r_32f, /* FLOAT */
		cgltf_component_type_max_enum
	}

	public enum cgltf_type : c_int
	{
		cgltf_type_invalid,
		cgltf_type_scalar,
		cgltf_type_vec2,
		cgltf_type_vec3,
		cgltf_type_vec4,
		cgltf_type_mat2,
		cgltf_type_mat3,
		cgltf_type_mat4,
		cgltf_type_max_enum
	}

	public enum cgltf_primitive_type : c_int
	{
		cgltf_primitive_type_invalid,
		cgltf_primitive_type_points,
		cgltf_primitive_type_lines,
		cgltf_primitive_type_line_loop,
		cgltf_primitive_type_line_strip,
		cgltf_primitive_type_triangles,
		cgltf_primitive_type_triangle_strip,
		cgltf_primitive_type_triangle_fan,
		cgltf_primitive_type_max_enum
	}

	public enum cgltf_alpha_mode : c_int
	{
		cgltf_alpha_mode_opaque,
		cgltf_alpha_mode_mask,
		cgltf_alpha_mode_blend,
		cgltf_alpha_mode_max_enum
	}

	public enum cgltf_animation_path_type : c_int
	{
		cgltf_animation_path_type_invalid,
		cgltf_animation_path_type_translation,
		cgltf_animation_path_type_rotation,
		cgltf_animation_path_type_scale,
		cgltf_animation_path_type_weights,
		cgltf_animation_path_type_max_enum
	}

	public enum cgltf_interpolation_type : c_int
	{
		cgltf_interpolation_type_linear,
		cgltf_interpolation_type_step,
		cgltf_interpolation_type_cubic_spline,
		cgltf_interpolation_type_max_enum
	}

	public enum cgltf_camera_type : c_int
	{
		cgltf_camera_type_invalid,
		cgltf_camera_type_perspective,
		cgltf_camera_type_orthographic,
		cgltf_camera_type_max_enum
	}

	public enum cgltf_light_type : c_int
	{
		cgltf_light_type_invalid,
		cgltf_light_type_directional,
		cgltf_light_type_point,
		cgltf_light_type_spot,
		cgltf_light_type_max_enum
	}

	public enum cgltf_data_free_method : c_int
	{
		cgltf_data_free_method_none,
		cgltf_data_free_method_file_release,
		cgltf_data_free_method_memory_free,
		cgltf_data_free_method_max_enum
	}

	[CRepr]
	public struct cgltf_extras
	{
		public cgltf_size start_offset; /* this field is deprecated and will be removed in the future; use data instead */
		public cgltf_size end_offset; /* this field is deprecated and will be removed in the future; use data instead */
		public char* data;
	}

	[CRepr]
	public struct cgltf_extension
	{
		public char* name;
		public char* data;
	}

	[CRepr]
	public struct cgltf_buffer
	{
		public char* name;
		public cgltf_size size;
		public char* uri;
		public void* data; /* loaded by cgltf_load_buffers */
		public cgltf_data_free_method data_free_method;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	public enum cgltf_meshopt_compression_mode : c_int
	{
		cgltf_meshopt_compression_mode_invalid,
		cgltf_meshopt_compression_mode_attributes,
		cgltf_meshopt_compression_mode_triangles,
		cgltf_meshopt_compression_mode_indices,
		cgltf_meshopt_compression_mode_max_enum
	}

	public enum cgltf_meshopt_compression_filter : c_int
	{
		cgltf_meshopt_compression_filter_none,
		cgltf_meshopt_compression_filter_octahedral,
		cgltf_meshopt_compression_filter_quaternion,
		cgltf_meshopt_compression_filter_exponential,
		cgltf_meshopt_compression_filter_max_enum
	}

	[CRepr]
	public struct cgltf_meshopt_compression
	{
		public cgltf_buffer* buffer;
		public cgltf_size offset;
		public cgltf_size size;
		public cgltf_size stride;
		public cgltf_size count;
		public cgltf_meshopt_compression_mode mode;
		public cgltf_meshopt_compression_filter filter;
	}

	[CRepr]
	public struct cgltf_buffer_view
	{
		public char* name;
		public cgltf_buffer* buffer;
		public cgltf_size offset;
		public cgltf_size size;
		public cgltf_size stride; /* 0 == automatically determined by accessor */
		public cgltf_buffer_view_type type;
		public void* data; /* overrides buffer->data if present, filled by extensions */
		public cgltf_bool has_meshopt_compression;
		public cgltf_meshopt_compression meshopt_compression;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_accessor_sparse
	{
		public cgltf_size count;
		public cgltf_buffer_view* indices_buffer_view;
		public cgltf_size indices_byte_offset;
		public cgltf_component_type indices_component_type;
		public cgltf_buffer_view* values_buffer_view;
		public cgltf_size values_byte_offset;
	}

	[CRepr]
	public struct cgltf_accessor
	{
		public char* name;
		public cgltf_component_type component_type;
		public cgltf_bool normalized;
		public cgltf_type type;
		public cgltf_size offset;
		public cgltf_size count;
		public cgltf_size stride;
		public cgltf_buffer_view* buffer_view;
		public cgltf_bool has_min;
		public cgltf_float[16] min;
		public cgltf_bool has_max;
		public cgltf_float[16] max;
		public cgltf_bool is_sparse;
		public cgltf_accessor_sparse sparse;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_attribute
	{
		public char* name;
		public cgltf_attribute_type type;
		public cgltf_int index;
		public cgltf_accessor* data;
	}

	[CRepr]
	public struct cgltf_image
	{
		public char* name;
		public char* uri;
		public cgltf_buffer_view* buffer_view;
		public char* mime_type;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	public enum cgltf_filter_type : c_int
	{
		cgltf_filter_type_undefined = 0,
		cgltf_filter_type_nearest = 9728,
		cgltf_filter_type_linear = 9729,
		cgltf_filter_type_nearest_mipmap_nearest = 9984,
		cgltf_filter_type_linear_mipmap_nearest = 9985,
		cgltf_filter_type_nearest_mipmap_linear = 9986,
		cgltf_filter_type_linear_mipmap_linear = 9987
	}

	public enum cgltf_wrap_mode : c_int
	{
		cgltf_wrap_mode_clamp_to_edge = 33071,
		cgltf_wrap_mode_mirrored_repeat = 33648,
		cgltf_wrap_mode_repeat = 10497
	}

	[CRepr]
	public struct cgltf_sampler
	{
		public char* name;
		public cgltf_filter_type mag_filter;
		public cgltf_filter_type min_filter;
		public cgltf_wrap_mode wrap_s;
		public cgltf_wrap_mode wrap_t;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_texture
	{
		public char* name;
		public cgltf_image* image;
		public cgltf_sampler* sampler;
		public cgltf_bool has_basisu;
		public cgltf_image* basisu_image;
		public cgltf_bool has_webp;
		public cgltf_image* webp_image;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_texture_transform
	{
		public cgltf_float[2] offset;
		public cgltf_float rotation;
		public cgltf_float[2] scale;
		public cgltf_bool has_texcoord;
		public cgltf_int texcoord;
	}

	[CRepr]
	public struct cgltf_texture_view
	{
		public cgltf_texture* texture;
		public cgltf_int texcoord;
		public cgltf_float scale; /* equivalent to strength for occlusion_texture */
		public cgltf_bool has_transform;
		public cgltf_texture_transform transform;
	}

	[CRepr]
	public struct cgltf_pbr_metallic_roughness
	{
		public cgltf_texture_view base_color_texture;
		public cgltf_texture_view metallic_roughness_texture;

		public cgltf_float[4] base_color_factor;
		public cgltf_float metallic_factor;
		public cgltf_float roughness_factor;
	}

	[CRepr]
	public struct cgltf_pbr_specular_glossiness
	{
		public cgltf_texture_view diffuse_texture;
		public cgltf_texture_view specular_glossiness_texture;

		public cgltf_float[4] diffuse_factor;
		public cgltf_float[3] specular_factor;
		public cgltf_float glossiness_factor;
	}

	[CRepr]
	public struct cgltf_clearcoat
	{
		public cgltf_texture_view clearcoat_texture;
		public cgltf_texture_view clearcoat_roughness_texture;
		public cgltf_texture_view clearcoat_normal_texture;

		public cgltf_float clearcoat_factor;
		public cgltf_float clearcoat_roughness_factor;
	}

	[CRepr]
	public struct cgltf_transmission
	{
		public cgltf_texture_view transmission_texture;
		public cgltf_float transmission_factor;
	}

	[CRepr]
	public struct cgltf_ior
	{
		public cgltf_float ior;
	}

	[CRepr]
	public struct cgltf_specular
	{
		public cgltf_texture_view specular_texture;
		public cgltf_texture_view specular_color_texture;
		public cgltf_float[3] specular_color_factor;
		public cgltf_float specular_factor;
	}

	[CRepr]
	public struct cgltf_volume
	{
		public cgltf_texture_view thickness_texture;
		public cgltf_float thickness_factor;
		public cgltf_float[3] attenuation_color;
		public cgltf_float attenuation_distance;
	}

	[CRepr]
	public struct cgltf_sheen
	{
		public cgltf_texture_view sheen_color_texture;
		public cgltf_float[3] sheen_color_factor;
		public cgltf_texture_view sheen_roughness_texture;
		public cgltf_float sheen_roughness_factor;
	}

	[CRepr]
	public struct cgltf_emissive_strength
	{
		public cgltf_float emissive_strength;
	}

	[CRepr]
	public struct cgltf_iridescence
	{
		public cgltf_float iridescence_factor;
		public cgltf_texture_view iridescence_texture;
		public cgltf_float iridescence_ior;
		public cgltf_float iridescence_thickness_min;
		public cgltf_float iridescence_thickness_max;
		public cgltf_texture_view iridescence_thickness_texture;
	}

	[CRepr]
	public struct cgltf_diffuse_transmission
	{
		public cgltf_texture_view diffuse_transmission_texture;
		public cgltf_float diffuse_transmission_factor;
		public cgltf_float[3] diffuse_transmission_color_factor;
		public cgltf_texture_view diffuse_transmission_color_texture;
	}

	[CRepr]
	public struct cgltf_anisotropy
	{
		public cgltf_float anisotropy_strength;
		public cgltf_float anisotropy_rotation;
		public cgltf_texture_view anisotropy_texture;
	}

	[CRepr]
	public struct cgltf_dispersion
	{
		public cgltf_float dispersion;
	}

	[CRepr]
	public struct cgltf_material
	{
		public char* name;
		public cgltf_bool has_pbr_metallic_roughness;
		public cgltf_bool has_pbr_specular_glossiness;
		public cgltf_bool has_clearcoat;
		public cgltf_bool has_transmission;
		public cgltf_bool has_volume;
		public cgltf_bool has_ior;
		public cgltf_bool has_specular;
		public cgltf_bool has_sheen;
		public cgltf_bool has_emissive_strength;
		public cgltf_bool has_iridescence;
		public cgltf_bool has_diffuse_transmission;
		public cgltf_bool has_anisotropy;
		public cgltf_bool has_dispersion;
		public cgltf_pbr_metallic_roughness pbr_metallic_roughness;
		public cgltf_pbr_specular_glossiness pbr_specular_glossiness;
		public cgltf_clearcoat clearcoat;
		public cgltf_ior ior;
		public cgltf_specular specular;
		public cgltf_sheen sheen;
		public cgltf_transmission transmission;
		public cgltf_volume volume;
		public cgltf_emissive_strength emissive_strength;
		public cgltf_iridescence iridescence;
		public cgltf_diffuse_transmission diffuse_transmission;
		public cgltf_anisotropy anisotropy;
		public cgltf_dispersion dispersion;
		public cgltf_texture_view normal_texture;
		public cgltf_texture_view occlusion_texture;
		public cgltf_texture_view emissive_texture;
		public cgltf_float[3] emissive_factor;
		public cgltf_alpha_mode alpha_mode;
		public cgltf_float alpha_cutoff;
		public cgltf_bool double_sided;
		public cgltf_bool unlit;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_material_mapping
	{
		public cgltf_size variant;
		public cgltf_material* material;
		public cgltf_extras extras;
	}

	[CRepr]
	public struct cgltf_morph_target
	{
		public cgltf_attribute* attributes;
		public cgltf_size attributes_count;
	}

	[CRepr]
	public struct cgltf_draco_mesh_compression
	{
		public cgltf_buffer_view* buffer_view;
		public cgltf_attribute* attributes;
		public cgltf_size attributes_count;
	}

	[CRepr]
	public struct cgltf_mesh_gpu_instancing
	{
		public cgltf_attribute* attributes;
		public cgltf_size attributes_count;
	}

	[CRepr]
	public struct cgltf_primitive
	{
		public cgltf_primitive_type type;
		public cgltf_accessor* indices;
		public cgltf_material* material;
		public cgltf_attribute* attributes;
		public cgltf_size attributes_count;
		public cgltf_morph_target* targets;
		public cgltf_size targets_count;
		public cgltf_extras extras;
		public cgltf_bool has_draco_mesh_compression;
		public cgltf_draco_mesh_compression draco_mesh_compression;
		public cgltf_material_mapping* mappings;
		public cgltf_size mappings_count;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_mesh
	{
		public char* name;
		public cgltf_primitive* primitives;
		public cgltf_size primitives_count;
		public cgltf_float* weights;
		public cgltf_size weights_count;
		public char** target_names;
		public cgltf_size target_names_count;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_skin
	{
		public char* name;
		public cgltf_node** joints;
		public cgltf_size joints_count;
		public cgltf_node* skeleton;
		public cgltf_accessor* inverse_bind_matrices;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_camera_perspective
	{
		public cgltf_bool has_aspect_ratio;
		public cgltf_float aspect_ratio;
		public cgltf_float yfov;
		public cgltf_bool has_zfar;
		public cgltf_float zfar;
		public cgltf_float znear;
		public cgltf_extras extras;
	}

	[CRepr]
	public struct cgltf_camera_orthographic
	{
		public cgltf_float xmag;
		public cgltf_float ymag;
		public cgltf_float zfar;
		public cgltf_float znear;
		public cgltf_extras extras;
	}

	[CRepr]
	public struct cgltf_camera
	{
		public char* name;
		public cgltf_camera_type type;
		public struct
		{
			public cgltf_camera_perspective perspective;
			public cgltf_camera_orthographic orthographic;
		} data;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_light
	{
		public char* name;
		public cgltf_float[3] color;
		public cgltf_float intensity;
		public cgltf_light_type type;
		public cgltf_float range;
		public cgltf_float spot_inner_cone_angle;
		public cgltf_float spot_outer_cone_angle;
		public cgltf_extras extras;
	}

	[CRepr]
	public struct cgltf_node
	{
		public char* name;
		public cgltf_node* parent;
		public cgltf_node** children;
		public cgltf_size children_count;
		public cgltf_skin* skin;
		public cgltf_mesh* mesh;
		public cgltf_camera* camera;
		public cgltf_light* light;
		public cgltf_float* weights;
		public cgltf_size weights_count;
		public cgltf_bool has_translation;
		public cgltf_bool has_rotation;
		public cgltf_bool has_scale;
		public cgltf_bool has_matrix;
		public cgltf_float[3] translation;
		public cgltf_float[4] rotation;
		public cgltf_float[3] scale;
		public cgltf_float[16] matrix;
		public cgltf_extras extras;
		public cgltf_bool has_mesh_gpu_instancing;
		public cgltf_mesh_gpu_instancing mesh_gpu_instancing;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_scene
	{
		public char* name;
		public cgltf_node** nodes;
		public cgltf_size nodes_count;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_animation_sampler
	{
		public cgltf_accessor* input;
		public cgltf_accessor* output;
		public cgltf_interpolation_type interpolation;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_animation_channel
	{
		public cgltf_animation_sampler* sampler;
		public cgltf_node* target_node;
		public cgltf_animation_path_type target_path;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_animation
	{
		public char* name;
		public cgltf_animation_sampler* samplers;
		public cgltf_size samplers_count;
		public cgltf_animation_channel* channels;
		public cgltf_size channels_count;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_material_variant
	{
		public char* name;
		public cgltf_extras extras;
	}

	[CRepr]
	public struct cgltf_asset
	{
		public char* copyright;
		public char* generator;
		public char* version;
		public char* min_version;
		public cgltf_extras extras;
		public cgltf_size extensions_count;
		public cgltf_extension* extensions;
	}

	[CRepr]
	public struct cgltf_data
	{
		public cgltf_file_type file_type;
		public void* file_data;

		public cgltf_asset asset;

		public cgltf_mesh* meshes;
		public cgltf_size meshes_count;

		public cgltf_material* materials;
		public cgltf_size materials_count;

		public cgltf_accessor* accessors;
		public cgltf_size accessors_count;

		public cgltf_buffer_view* buffer_views;
		public cgltf_size buffer_views_count;

		public cgltf_buffer* buffers;
		public cgltf_size buffers_count;

		public cgltf_image* images;
		public cgltf_size images_count;

		public cgltf_texture* textures;
		public cgltf_size textures_count;

		public cgltf_sampler* samplers;
		public cgltf_size samplers_count;

		public cgltf_skin* skins;
		public cgltf_size skins_count;

		public cgltf_camera* cameras;
		public cgltf_size cameras_count;

		public cgltf_light* lights;
		public cgltf_size lights_count;

		public cgltf_node* nodes;
		public cgltf_size nodes_count;

		public cgltf_scene* scenes;
		public cgltf_size scenes_count;

		public cgltf_scene* scene;

		public cgltf_animation* animations;
		public cgltf_size animations_count;

		public cgltf_material_variant* variants;
		public cgltf_size variants_count;

		public cgltf_extras extras;

		public cgltf_size data_extensions_count;
		public cgltf_extension* data_extensions;

		public char** extensions_used;
		public cgltf_size extensions_used_count;

		public char** extensions_required;
		public cgltf_size extensions_required_count;

		public char* json;
		public cgltf_size json_size;

		public void* bin;
		public cgltf_size bin_size;

		public cgltf_memory_options memory;
		public cgltf_file_options file;
	}

	[CLink] public static extern cgltf_result cgltf_parse(cgltf_options* options, void* data, cgltf_size size, cgltf_data** out_data);

	[CLink] public static extern cgltf_result cgltf_parse_file(cgltf_options* options, char* path, cgltf_data** out_data);

	[CLink] public static extern cgltf_result cgltf_load_buffers(cgltf_options* options, cgltf_data* data, char* gltf_path);

	[CLink] public static extern cgltf_result cgltf_load_buffer_base64(cgltf_options* options, cgltf_size size, char* base64, void** out_data);

	[CLink] public static extern cgltf_size cgltf_decode_string(char* string);

	[CLink] public static extern cgltf_size cgltf_decode_uri(char* uri);

	[CLink] public static extern cgltf_result cgltf_validate(cgltf_data* data);

	[CLink] public static extern void cgltf_free(cgltf_data* data);

	[CLink] public static extern void cgltf_node_transform_local(cgltf_node* node, cgltf_float* out_matrix);

	[CLink] public static extern void cgltf_node_transform_world(cgltf_node* node, cgltf_float* out_matrix);

	[CLink] public static extern uint8* cgltf_buffer_view_data(cgltf_buffer_view* view);

	[CLink] public static extern cgltf_accessor* cgltf_find_accessor(cgltf_primitive* prim, cgltf_attribute_type type, cgltf_int index);

	[CLink] public static extern cgltf_bool cgltf_accessor_read_float(cgltf_accessor* accessor, cgltf_size index, cgltf_float* val, cgltf_size element_size);

	[CLink] public static extern cgltf_bool cgltf_accessor_read_uint(cgltf_accessor* accessor, cgltf_size index, cgltf_uint* val, cgltf_size element_size);

	[CLink] public static extern cgltf_size cgltf_accessor_read_index(cgltf_accessor* accessor, cgltf_size index);

	[CLink] public static extern cgltf_size cgltf_num_components(cgltf_type type);

	[CLink] public static extern cgltf_size cgltf_component_size(cgltf_component_type component_type);

	[CLink] public static extern cgltf_size cgltf_calc_size(cgltf_type type, cgltf_component_type component_type);

	[CLink] public static extern cgltf_size cgltf_accessor_unpack_floats(cgltf_accessor* accessor, cgltf_float* out_float, cgltf_size float_count);

	[CLink] public static extern cgltf_size cgltf_accessor_unpack_indices(cgltf_accessor* accessor, void* out_ptr, cgltf_size out_component_size, cgltf_size index_count);

	[CLink] public static extern cgltf_size cgltf_mesh_index(cgltf_data* data, cgltf_mesh* object);

	[CLink] public static extern cgltf_size cgltf_material_index(cgltf_data* data, cgltf_material* object);

	[CLink] public static extern cgltf_size cgltf_accessor_index(cgltf_data* data, cgltf_accessor* object);

	[CLink] public static extern cgltf_size cgltf_buffer_view_index(cgltf_data* data, cgltf_buffer_view* object);

	[CLink] public static extern cgltf_size cgltf_buffer_index(cgltf_data* data, cgltf_buffer* object);

	[CLink] public static extern cgltf_size cgltf_image_index(cgltf_data* data, cgltf_image* object);

	[CLink] public static extern cgltf_size cgltf_texture_index(cgltf_data* data, cgltf_texture* object);

	[CLink] public static extern cgltf_size cgltf_sampler_index(cgltf_data* data, cgltf_sampler* object);

	[CLink] public static extern cgltf_size cgltf_skin_index(cgltf_data* data, cgltf_skin* object);

	[CLink] public static extern cgltf_size cgltf_camera_index(cgltf_data* data, cgltf_camera* object);

	[CLink] public static extern cgltf_size cgltf_light_index(cgltf_data* data, cgltf_light* object);

	[CLink] public static extern cgltf_size cgltf_node_index(cgltf_data* data, cgltf_node* object);

	[CLink] public static extern cgltf_size cgltf_scene_index(cgltf_data* data, cgltf_scene* object);

	[CLink] public static extern cgltf_size cgltf_animation_index(cgltf_data* data, cgltf_animation* object);

	[CLink] public static extern cgltf_size cgltf_animation_sampler_index(cgltf_animation* animation, cgltf_animation_sampler* object);

	[CLink] public static extern cgltf_size cgltf_animation_channel_index(cgltf_animation* animation, cgltf_animation_channel* object);

	[CLink, Obsolete("this function is deprecated and will be removed in the future; use cgltf_extras::data instead")]
	public static extern cgltf_result cgltf_copy_extras_json(cgltf_data* data, cgltf_extras* extras, char* dest, cgltf_size* dest_size);
}