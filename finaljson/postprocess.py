import os
import re

BASE_URL = "https://heasarc.gsfc.nasa.gov"
BIBLIO_BASE = "https://heasarc.gsfc.nasa.gov/docs/heasarc/missions/biblio/"

INPUT_DIR = "static_output"
OUTPUT_DIR = "processed"
INCLUDE_DIR = "includes"

include_pattern = re.compile(r'<!--#include virtual="([^"]+)"-->')

def replace_includes(html):
    def replacer(match):
        virtual_path = match.group(1)
        filename = virtual_path.lstrip("/")
        filepath = os.path.join(INCLUDE_DIR, os.path.basename(filename))

        if not os.path.exists(filepath):
            print(f"WARNING: Include file not found: {filepath}")
            return ""

        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()

    return include_pattern.sub(replacer, html)


def rewrite_urls(html):
    # 1️⃣ Convert mission-internal links to local relative links
    html = re.sub(
        r'(?<=["\'])/docs/heasarc/missions/([^"\']+)',
        lambda m: m.group(1),
        html
    )

    # 2️⃣ Rewrite biblio/... links
    html = re.sub(
        r'(?<=["\'])biblio/([^"\']+)',
        lambda m: BIBLIO_BASE + m.group(1),
        html
    )

    # 3️⃣ Rewrite remaining root-relative URLs
    html = re.sub(
        r'(?<=["\'])/(?!/)([^"\']+)',
        lambda m: BASE_URL + "/" + m.group(1),
        html
    )

    return html


def process_file(input_path, output_path):
    with open(input_path, "r", encoding="utf-8") as f:
        html = f.read()

    html = replace_includes(html)
    html = rewrite_urls(html)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)

def main():
    for root, dirs, files in os.walk(INPUT_DIR):
        for file in files:
            if file.endswith(".html"):
                input_path = os.path.join(root, file)

                # Preserve directory structure
                rel_path = os.path.relpath(input_path, INPUT_DIR)
                output_path = os.path.join(OUTPUT_DIR, rel_path)

                print(f"Processing: {rel_path}")
                process_file(input_path, output_path)

    print("\nDone. All files written to 'processed/'")

    
if __name__ == "__main__":
    main()
