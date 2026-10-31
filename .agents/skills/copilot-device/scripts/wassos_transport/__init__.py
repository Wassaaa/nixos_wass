def main() -> int:
    print("""Task: add the ALSA runtime library to Horizon's launcher environment.
This prints instructions only; it does not change your files.

In the Horizon checkout, edit launcher/.envrc. Keep your existing
HORIZON_MSA_CLIENT_ID line. Add the following after it; if you already have
`use nix`, keep just one copy and put the library lines after it:

    use nix
    horizon_alsa_lib=$(nix-build '<nixpkgs>' -A alsa-lib --no-out-link) || return 1
    export LD_LIBRARY_PATH="$horizon_alsa_lib/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export NIX_LD_LIBRARY_PATH="$horizon_alsa_lib/lib${NIX_LD_LIBRARY_PATH:+:$NIX_LD_LIBRARY_PATH}"

From the launcher directory, run `direnv allow`, then `cargo run --release`.
The first load may download or build ALSA. Run Cargo directly in the direnv
environment: starting another nix-shell can replace LD_LIBRARY_PATH.

This addresses the reported missing libasound.so.2; the failing program has
not been identified, and further missing libraries may need investigation.
Avoid committing your local .envrc to the Horizon checkout.""")
    return 0
