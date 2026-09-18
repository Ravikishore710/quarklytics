"""Small CLI wrapper for the same database assertions used by pytest."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[2]
raise SystemExit(subprocess.call([sys.executable,'-m','pytest','-q'],cwd=root))
