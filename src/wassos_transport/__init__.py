import os


def main() -> int:
    print("Task: check the current Hyprland terminal for NVIDIA VA-API settings.")
    print("This is read-only and does not check whether video decoding works.")
    print("Review output for sensitive information before sharing it.")

    checks = {
        "LIBVA_DRIVER_NAME": "nvidia",
        "NVD_BACKEND": "direct",
        "XDG_SESSION_TYPE": "wayland",
    }
    passed = True
    for name, expected in checks.items():
        if os.environ.get(name) == expected:
            print(f"{name}: expected value present ({expected})")
        else:
            print(f"{name}: expected {expected}; missing or different")
            passed = False

    for name in ("HYPRLAND_INSTANCE_SIGNATURE", "WAYLAND_DISPLAY"):
        if os.environ.get(name):
            print(f"{name}: present")
        else:
            print(f"{name}: missing")
            passed = False

    if passed:
        print("The current terminal has the expected settings. Other launchers may inherit a different environment.")
        return 0
    print("Start a fresh Hyprland login after applying the configuration, then check again.")
    return 1
