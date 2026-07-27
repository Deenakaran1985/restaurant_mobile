#!/usr/bin/env python3
import os
import re

def main():
    print("=== ENFORCING AGP 8.5.2, KOTLIN 2.0.20, AND GRADLE 8.9 ===")
    
    # 1. Update versions across all Android gradle, kts, and properties files
    for root, _, files in os.walk("android"):
        for f in files:
            if f.endswith((".gradle", ".kts", ".properties", ".gradle.kts")):
                path = os.path.join(root, f)
                try:
                    with open(path, "r", encoding="utf-8") as file:
                        content = file.read()
                    
                    orig = content
                    # Pin AGP application and library plugins to 8.5.2
                    content = re.sub(r'(id\s*[\(\"\']com\.android\.application[\)\"\']\s*version\s*[\"\'])[^\"\']+([\"\'])', r'\g<1>8.5.2\2', content)
                    content = re.sub(r'(id\s*[\(\"\']com\.android\.library[\)\"\']\s*version\s*[\"\'])[^\"\']+([\"\'])', r'\g<1>8.5.2\2', content)
                    content = re.sub(r'(com\.android\.tools\.build:gradle:)[0-9\.]+', r'\g<1>8.5.2', content)
                    
                    # Pin Kotlin Android plugin and classpath to 2.0.20
                    content = re.sub(r'(id\s*[\(\"\']org\.jetbrains\.kotlin\.android[\)\"\']\s*version\s*[\"\'])[^\"\']+([\"\'])', r'\g<1>2.0.20\2', content)
                    content = re.sub(r'(org\.jetbrains\.kotlin:kotlin-gradle-plugin:)[0-9\.]+', r'\g<1>2.0.20', content)
                    content = re.sub(r'ext\.kotlin_version\s*=\s*[\"\'][^\"\']+[\"\']', "ext.kotlin_version = '2.0.20'", content)
                    
                    # Pin Gradle wrapper to 8.9-all
                    if f == "gradle-wrapper.properties":
                        content = re.sub(r'gradle-[0-9\.]+-(all|bin)\.zip', 'gradle-8.9-all.zip', content)
                    
                    if content != orig:
                        with open(path, "w", encoding="utf-8") as file:
                            file.write(content)
                        print(f"✅ Updated toolchains in: {path}")
                except Exception as e:
                    print(f"⚠️ Error reading {path}: {e}")

    # 2. Configure root buildscript classpath in build.gradle.kts or build.gradle
    kts_path = "android/build.gradle.kts"
    groovy_path = "android/build.gradle"
    
    if os.path.exists(kts_path):
        with open(kts_path, "r", encoding="utf-8") as file:
            content = file.read()
        if "kotlin-gradle-plugin" not in content:
            buildscript_block = """
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.20")
    }
}
"""
            with open(kts_path, "a", encoding="utf-8") as file:
                file.write(buildscript_block)
            print("✅ Injected Kotlin buildscript classpath into android/build.gradle.kts")
    elif os.path.exists(groovy_path):
        with open(groovy_path, "r", encoding="utf-8") as file:
            content = file.read()
        if "kotlin-gradle-plugin" not in content:
            lines = content.splitlines()
            new_lines = []
            for line in lines:
                new_lines.append(line)
                if "dependencies {" in line and "buildscript" in content:
                    new_lines.append('        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.20"')
            with open(groovy_path, "w", encoding="utf-8") as file:
                file.write("\n".join(new_lines) + "\n")
            print("✅ Injected Kotlin buildscript classpath into android/build.gradle")

    # 3. Apply global and local properties for AGP opt-outs and memory
    gradle_dir = os.path.expanduser("~/.gradle")
    os.makedirs(gradle_dir, exist_ok=True)
    global_props = os.path.join(gradle_dir, "gradle.properties")
    local_props = "android/gradle.properties"
    
    with open(global_props, "a", encoding="utf-8") as file:
        file.write("\nandroid.newDsl=false\n")
        
    with open(local_props, "a", encoding="utf-8") as file:
        file.write("\nandroid.newDsl=false\n")
        file.write("android.defaults.buildfeatures.buildconfig=true\n")
        file.write("org.gradle.jvmargs=-Xmx4G -XX:+HeapDumpOnOutOfMemoryError\n")
    print("✅ Configured AGP fallback properties in global and local gradle.properties")

if __name__ == "__main__":
    main()

