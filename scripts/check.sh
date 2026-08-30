#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
shader_root="$project_root/shaders"
preprocessor=${CC:-cc}

command -v "$preprocessor" >/dev/null 2>&1 || {
    echo "error: C preprocessor not found: $preprocessor" >&2
    exit 1
}

command -v glslangValidator >/dev/null 2>&1 || {
    echo "error: glslangValidator is required" >&2
    exit 1
}

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/source-water-check.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

mkdir -p "$work_dir/lib"
cp "$shader_root/lib/"*.glsl "$work_dir/lib/"

extract_locale_keys() {
    locale_file=$1
    output_file=$2

    awk -F= '
        NF >= 2 && $1 !~ /^[[:space:]]*#/ {
            print $1
        }
    ' "$locale_file" | LC_ALL=C sort >"$output_file"
}

validate_locale_keys() {
    locale_file=$1
    locale_name=$(basename "$locale_file")
    all_keys="$work_dir/$locale_name.keys"
    unique_keys="$work_dir/$locale_name.unique.keys"

    extract_locale_keys "$locale_file" "$all_keys"
    LC_ALL=C sort -u "$all_keys" >"$unique_keys"

    if ! cmp -s "$all_keys" "$unique_keys"; then
        echo "error: duplicate localization keys: $locale_file" >&2
        diff -u "$unique_keys" "$all_keys" >&2 || true
        exit 1
    fi
}

validate_locales() {
    english_locale="$shader_root/lang/en_US.lang"
    russian_locale="$shader_root/lang/ru_RU.lang"
    english_keys="$work_dir/en_US.lang.keys"
    russian_keys="$work_dir/ru_RU.lang.keys"

    validate_locale_keys "$english_locale"
    validate_locale_keys "$russian_locale"

    if ! cmp -s "$english_keys" "$russian_keys"; then
        echo "error: English and Russian localization keys differ" >&2
        diff -u "$english_keys" "$russian_keys" >&2 || true
        exit 1
    fi

    screen_options=$(sed -n \
        's/^screen[[:space:]]*=[[:space:]]*//p' \
        "$shader_root/shaders.properties")

    for option_name in $screen_options; do
        for locale_keys in "$english_keys" "$russian_keys"; do
            grep -Fqx "option.$option_name" "$locale_keys" || {
                echo "error: missing option.$option_name in $locale_keys" >&2
                exit 1
            }
            grep -Fqx "option.$option_name.comment" "$locale_keys" || {
                echo "error: missing option.$option_name.comment in $locale_keys" >&2
                exit 1
            }
        done
    done

    water_presets=$(sed -n \
        's/^#define WATER_PRESET [^[]*\[\([^]]*\)\].*/\1/p' \
        "$shader_root/lib/water_material.glsl")

    for water_preset in $water_presets; do
        for locale_keys in "$english_keys" "$russian_keys"; do
            grep -Fqx "value.WATER_PRESET.$water_preset" "$locale_keys" || {
                echo "error: missing water preset $water_preset in $locale_keys" >&2
                exit 1
            }
        done
    done
}

preprocess_shader() {
    shader_file=$1

    sed \
        -e '/^[[:space:]]*#version[[:space:]]/d' \
        -e 's|#include "/lib/|#include "|' \
        "$shader_file" |
        "$preprocessor" \
            -E \
            -P \
            -x c \
            -undef \
            -nostdinc \
            -DIS_IRIS=1 \
            -I"$work_dir/lib" \
            -
}

validate_shader() {
    shader_file=$1
    validation_log="$work_dir/glslang.log"

    case "$shader_file" in
        *.fsh) shader_stage=frag ;;
        *.vsh) shader_stage=vert ;;
        *)
            echo "error: unsupported shader extension: $shader_file" >&2
            exit 1
            ;;
    esac

    if ! preprocess_shader "$shader_file" |
        glslangValidator \
            --stdin \
            -d \
            --glsl-version 120 \
            -S "$shader_stage" \
            >"$validation_log" 2>&1; then
        echo "error: shader validation failed: $shader_file" >&2
        sed -n '1,120p' "$validation_log" >&2
        exit 1
    fi
}

validate_locales

for shader_file in "$shader_root"/*.fsh "$shader_root"/*.vsh; do
    validate_shader "$shader_file"
done

for water_preset in 0 1 2 3 4 5 6 7 8; do
    for normal_mode in 0 1; do
        for water_quality in 0 1 2; do
            for ssr_quality in 0 1 2 3 4; do
                for ssr_resolution in 0 1 2 3; do
                    sed \
                        -e "s/^#define WATER_PRESET .*/#define WATER_PRESET $water_preset/" \
                        -e "s/^#define WATER_NORMAL_MODE .*/#define WATER_NORMAL_MODE $normal_mode/" \
                        -e "s/^#define WATER_QUALITY .*/#define WATER_QUALITY $water_quality/" \
                        -e "s/^#define SSR_QUALITY .*/#define SSR_QUALITY $ssr_quality/" \
                        -e "s/^#define SSR_RESOLUTION .*/#define SSR_RESOLUTION $ssr_resolution/" \
                        "$shader_root/lib/water_material.glsl" \
                        >"$work_dir/lib/water_material.glsl"

                    validate_shader "$shader_root/gbuffers_water.fsh"
                    validate_shader "$shader_root/composite.fsh"
                    validate_shader "$shader_root/composite1.fsh"
                done
            done
        done
    done
done

echo "Validated English/Russian localization, all shader programs, and 3,240 water fragment variants."
