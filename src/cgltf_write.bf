/**
 * cgltf_write - a single-file glTF 2.0 writer written in C99.
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
 * `CGLTF_WRITE_IMPLEMENTATION` before including this file to get the
 * function definitions.
 *
 * Reference:
 * `cgltf_result cgltf_write_file(const cgltf_options* options, const char*
 * path, const cgltf_data* data)` writes a glTF data to the given file path.
 * If `options->type` is `cgltf_file_type_glb`, both JSON content and binary
 * buffer of the given glTF data will be written in a GLB format.
 * Otherwise, only the JSON part will be written.
 * External buffers and images are not written out. `data` is not deallocated.
 *
 * `cgltf_size cgltf_write(const cgltf_options* options, char* buffer,
 * cgltf_size size, const cgltf_data* data)` writes JSON into the given memory
 * buffer. Returns the number of bytes written to `buffer`, including a null
 * terminator. If buffer is null, returns the number of bytes that would have
 * been written. `data` is not deallocated.
 */

using System;
using System.Interop;

namespace cgltf;

#if !CGLTF_NO_WRITE
extension cgltf
{
	[CLink] public static extern cgltf_result cgltf_write_file(cgltf_options* options, char* path, cgltf_data* data);
	
	[CLink] public static extern cgltf_size cgltf_write(cgltf_options* options, char* buffer, cgltf_size size, cgltf_data* data);
#endif
}