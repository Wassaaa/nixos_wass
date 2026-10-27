{
  lib,
  buildNpmPackage,
  copyDesktopItems,
  electron,
  importNpmLock,
  makeDesktopItem,
  makeWrapper,
  windowsAppSrc,
}:
let
  package = builtins.fromJSON (builtins.readFile "${windowsAppSrc}/package.json");
  packageLock = builtins.fromJSON (builtins.readFile "${windowsAppSrc}/package-lock.json");
  productionPackage = builtins.removeAttrs package [ "devDependencies" ];
  productionLock = packageLock // {
    packages =
      lib.filterAttrs (_: dependency: !(dependency.dev or false)) packageLock.packages
      // {
        "" = builtins.removeAttrs packageLock.packages."" [ "devDependencies" ];
      };
  };
in
buildNpmPackage {
  pname = "windows-app-for-linux";
  version = package.version;
  src = windowsAppSrc;

  npmDeps = importNpmLock {
    package = productionPackage;
    packageLock = productionLock;
  };
  npmConfigHook = importNpmLock.npmConfigHook;
  npmFlags = [ "--omit=dev" "--ignore-scripts" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ copyDesktopItems makeWrapper ];

  desktopItems = [
    (makeDesktopItem {
      name = "windows-app-for-linux";
      desktopName = "Windows App";
      comment = "Unofficial Windows App web client";
      exec = "windows-app-for-linux";
      icon = "windows-app-for-linux";
      categories = [ "Network" "Office" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -d "$out/share/windows-app-for-linux"
    cp -r app assets node_modules package.json "$out/share/windows-app-for-linux/"
    install -Dm644 assets/icons/icon.svg "$out/share/icons/hicolor/scalable/apps/windows-app-for-linux.svg"
    install -Dm644 LICENSE "$out/share/licenses/windows-app-for-linux/LICENSE"
    makeWrapper ${electron}/bin/electron "$out/bin/windows-app-for-linux" \
      --add-flags "$out/share/windows-app-for-linux"

    runHook postInstall
  '';

  meta = {
    description = "Unofficial Windows App web client for Linux";
    homepage = "https://github.com/mariuszkopowski/windows-app-for-linux";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "windows-app-for-linux";
  };
}
