import { platform } from 'node:os'
import { type Build } from 'xbuild'

const build: Build = {
    common: {
        project: 'cgltf',
        archs: ['x64'],
        defines: ['CGLTF_IMPLEMENTATION', 'CGLTF_WRITE_IMPLEMENTATION'],
        options: [],
        variables: [],
        copy: {
            'cgltf/cgltf.h': 'cgltf/cgltf.c',
            'cgltf/cgltf_write.h': 'cgltf/cgltf_write.c'
        },
        subdirectories: [],
        libraries: {
            cgltf: {
                sources: ['cgltf/cgltf.c']
            },
            cgltf_write: {
                sources: ['cgltf/cgltf_write.c']
            }
        },
        buildDir: 'build',
        buildOutDir: 'libs',
        buildFlags: []
    },
    platforms: {
        win32: {
            windows: {},
            android: {
                archs: ['x86', 'x86_64', 'armeabi-v7a', 'arm64-v8a'],
            }
        },
        linux: {
            linux: {},
        },
        darwin: {
            macos: {}
        }
    }
}

export default build;