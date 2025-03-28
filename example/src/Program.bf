using System;
using System.Diagnostics;
using static cgltf.cgltf;

namespace example;

class Program
{
	public static int Main(String[] args)
	{
		cgltf_options options = .();
		cgltf_data* data = null;
		cgltf_result result = cgltf_parse_file(&options, "Duck.gltf", &data);

		Debug.WriteLine($"mesh count: {data.meshes_count}");
		Debug.WriteLine($"json size: {data.json_size}");

		if (result == .cgltf_result_success)
		{
			/* TODO make awesome stuff */
			cgltf_free(data);
		}

		return 0;
	}
}