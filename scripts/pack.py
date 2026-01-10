from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent.parent

addon = "GimmeBuffsPls"
package_dir = ROOT / "tmp" / addon
package_dir.mkdir(exist_ok=True, parents=True)
for source in ROOT.iterdir():
    if source.suffix not in [".lua", ".toc"]:
        continue
    print(source, "->", package_dir / source.name)
    shutil.copy(source, package_dir / source.name)
shutil.make_archive(ROOT / addon, "zip", package_dir)
shutil.rmtree(ROOT / "tmp")
