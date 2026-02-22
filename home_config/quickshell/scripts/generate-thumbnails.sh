#!/bin/bash

# Thumbnail generator for Quickshell wallpapers
# Generates small thumbnails for all wallpapers in the specified directory

set -e

THUMB_SIZE="300x200"
THUMB_DIR_SUFFIX=".thumbs"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpapers"

usage() {
	echo "Usage: $0 [--watch] [wallpaper_dir]"
	echo "  --watch    Watch for changes and regenerate thumbnails"
	echo "  wallpaper_dir    Path to wallpaper directory (default: ~/Pictures/Wallpapers)"
	exit 1
}

WATCH_MODE=false
WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"

while [[ $# -gt 0 ]]; do
	case $1 in
	--watch)
		WATCH_MODE=true
		shift
		;;
	*)
		WALLPAPER_DIR="$1"
		shift
		;;
	esac
done

IMAGE_EXTENSIONS="jpg|jpeg|png|webp|gif|bmp"

mkdir -p "$CACHE_DIR"

generate_thumbnails() {
	local source_dir="$1"
	local thumb_dir="${CACHE_DIR}/$(basename "$source_dir")"

	mkdir -p "$thumb_dir"

	find "$source_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.bmp" \) | while read -r img; do
		local filename=$(basename "$img")
		local thumb_path="${thumb_dir}/${filename%.*}.jpg"

		if [[ ! -f "$thumb_path" ]] || [[ "$img" -nt "$thumb_path" ]]; then
			convert "$img" -auto-orient -resize "${THUMB_SIZE}^" -gravity center -extent "${THUMB_SIZE}" -quality 85 "$thumb_path" 2>/dev/null || {
				echo "Failed to generate thumbnail for: $filename"
			}
		fi
	done

	local json_file="${thumb_dir}/thumbnails.json"
	{
		echo '{'
		echo '  "thumbnails": ['
		find "$thumb_dir" -maxdepth 1 -type f -name "*.jpg" | while read -r thumb; do
			local thumb_name=$(basename "$thumb")
			local orig_name="${thumb_name%.jpg}"
			echo "    {\"name\": \"$orig_name\", \"path\": \"$thumb\"},"
		done
		echo '  ]'
		echo '}'
	} >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"
}

generate_all_thumbnails() {
	generate_thumbnails "$WALLPAPER_DIR"
}

if [[ "$WATCH_MODE" == true ]]; then
	while inotifywait -e close_write,moved_to -q -r "$WALLPAPER_DIR" 2>/dev/null; do
		generate_thumbnails "$WALLPAPER_DIR"
	done
else
	generate_all_thumbnails
fi
