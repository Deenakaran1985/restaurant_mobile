#!/usr/bin/env python3
import os
import glob
import re

def main():
    print("=== SANITIZING TRANSITIVE JNI & ANDROID MODULES IN PUB-CACHE ===")
    pub_cache = os.path.expanduser("~/.pub-cache")
    pattern = os.path.join(pub_cache, "**", "jni-*", "android", "build.gradle")
    
    for path in glob.glob(pattern, recursive=True):
        try:
            with open(path, "r", encoding="utf-8") as file:
                content = file.read()
            
            orig = content
            # Remove incompatible legacy kotlin toolchain blocks
            content = re.sub(r"kotlin\s*\{\s*[^{}]*jvmToolchain[^{}]*\}", "", content)
            # Ensure mandatory unconditional namespace declaration to eliminate AGP 8+/9+ NullPointerException
            content = re.sub(r"if\s*\([^)]*namespace[^)]*\)\s*\{\s*namespace\s*[\x27\"]([^\x27\"]+)[\x27\"]\s*\}", r"\n    namespace '\1'\n", content)
            if "namespace " not in content:
                content = content.replace("compileSdk", "namespace 'com.github.dart_lang.jni'\n    compileSdk")
            
            if content != orig:
                with open(path, "w", encoding="utf-8") as file:
                    file.write(content)
                print(f"✅ Successfully sanitized: {path}")
        except Exception as e:
            print(f"⚠️ Error processing {path}: {e}")

if __name__ == "__main__":
    main()

