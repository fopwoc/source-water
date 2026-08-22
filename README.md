# Source Water

Source Water is a Minecraft Iris shader pack that recreates Source Engine water by reverse-engineering the 2004 and 2007 renderer revisions, shaders, and material behavior.

The 2007 path is the default and follows Episode Two water materials. The optional 2004 normal-animation mode restores the original 29-frame animated normal map and classic single-flow sampling. Source planar reflections are adapted to Minecraft with screen-space reflections, while refraction, Fresnel, fog, cheap-water distance blending, and underwater behavior follow their Source counterparts where the rendering pipelines permit it.

Pairs especially well with [Squake](https://modrinth.com/mod/squake-fabric-updated)

## Installation

1. Download `Source-Water-<version>.zip` from GitHub Actions or Releases.
2. Place the ZIP in Minecraft's `shaderpacks` directory without extracting it.
3. Select **Source Water** in Iris.

Water appearance is selected manually through shader options. It is not inferred from Minecraft biomes.

## Development

Validate all shader variants and build the distributable ZIP:

```sh
./scripts/check.sh
./scripts/build.sh
```

## References and attribution

The implementation is based on reverse engineering and study of the [Source SDK 2004](https://github.com/Source-SDK-Base-Legacy-Project/source-sdk-2004) and [Source SDK 2007](https://github.com/Source-SDK-Base-Legacy-Project/source-sdk-2007).

Developed with assistance from **ChatGPT 5.6 Sol**.

This is an independent, unofficial fan project. It is not affiliated with or endorsed by Valve, Mojang, Microsoft or Iris.

Copyright (C) 2026 Ilya Dobryakov. Original project code and documentation are available under the [WTFPL](LICENSE). Source-derived assets and inherited shader components are not relicensed; see [COPYRIGHT](COPYRIGHT) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
