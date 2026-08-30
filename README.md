# Source Water

Shader pack for Iris that replaces vanilla water rendering with a reconstruction of water from Source Engine games. Its goal is to bring the appearance and behavior of classic Source water into Minecraft without turning the pack into a general lighting or art-style overhaul.

The implementation is based primarily on the Source 2007 renderer, with the 2004 renderer preserved as an optional classic normal-animation mode.

The main inspiration for this pack was a random YouTube video about Chinese cs 1.6 F2P version where some Source graphical features was packported. Such as *water*!

> [!NOTE]
> This project contains AI-generated code. See [AI_USAGE.md](AI_USAGE.md) for details.

## Recreated Source behavior

- Source's expensive and cheap water rendering paths, with a distance-based LOD transition between them.
- Material-specific surface and underwater fog colors, fog ranges, refraction, reflection distortion, and normal-map flow.
- Fresnel-driven reflections, three-layer Source 2007 normal movement, and the original 29-frame Source 2004 animated normal map.
- Separate underwater material behavior and optional full-screen water warp.

## Adaptations

- Source planar reflection render targets are replaced with screen-space reflections for visible scene geometry and a sky fallback when SSR cannot provide a result.
- Source environment cubemaps are approximated with a light-aware Minecraft sky reflection, including the cheap-water path.
- Source-unit fog distances are converted to Minecraft blocks, while the expensive-to-cheap water transition is configured in chunks.
- Vanilla underwater tint and fog are removed so that the selected Source material controls underwater color and visibility.

## Included materials

- Half-Life 2 — Canals 03
- Half-Life 2 — Canals Clear
- Half-Life 2: Lost Coast — ATI
- Half-Life 2: Episode One — Riverbed 01
- Half-Life 2: Episode Two — Riverbed 01
- Half-Life 2: Episode Two — Riverbed 02
- Half-Life 2: Episode Two — Silo
- Half-Life 2: Episode Two — Tunnels
- Counter-Strike: Source — Militia

Pairs especially well with [Squake](https://modrinth.com/mod/squake-fabric-updated).

![Source 2007 water in the Episode Two tunnels](.github/assets/tunnels_2007.png)
![Source 2004 water in the Episode Two tunnels](.github/assets/tunnels_2004.png)
![Cheap-water rendering at a distance](.github/assets/cheap.png)

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

Original project code and documentation are available under the [WTFNMFPL](LICENSE). Source-derived assets and inherited shader components are not relicensed; see [COPYRIGHT](COPYRIGHT) and [THIRD_PARTY.md](THIRD_PARTY.md).
