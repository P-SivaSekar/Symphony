import re

log_path = r"C:\Users\psiva\.gemini\antigravity\brain\197c61e5-ff1b-438e-9fd1-e5456ba699b8\.system_generated\tasks\task-625.log"
output_path = r"D:\Studies\Projects\Music Player\firestore_songs.json"

with open(log_path, "r", encoding="utf-8") as f:
    text = f.read()

start_marker = "=== FIRESTORE DUMP START ==="
end_marker = "=== FIRESTORE DUMP END ==="

start_idx = text.find(start_marker)
if start_idx == -1:
    print("Start marker not found.")
    exit(1)

end_idx = text.find(end_marker, start_idx)
if end_idx == -1:
    print("End marker not found.")
    exit(1)

dump_content = text[start_idx + len(start_marker):end_idx]

# The dump is split by "I/flutter (PID): " prefixes, we need to clean them up.
lines = dump_content.split('\n')
clean_lines = []
for line in lines:
    idx = line.find("): ")
    if idx != -1:
        clean_lines.append(line[idx+3:])
    else:
        # Fallback
        if "I/flutter" in line:
            continue
        clean_lines.append(line)

json_str = "".join(clean_lines).strip()

with open(output_path, "w", encoding="utf-8") as f:
    f.write(json_str)
print(f"Dump written to {output_path} successfully!")
