"""Build the game's sound effects from free (CC0 / CC-BY) packs.

Usage: python3 tools/import_sfx.py <packs_dir>
<packs_dir> holds the unzipped Kenney packs (kenney_*) and OpenGameArt downloads (oga/).
Every source is trimmed, faded, peak-normalised and written as mono Ogg Vorbis to
assets/audio/<name>_<n>.ogg (the Audio autoload picks a random variant). Replaced
generated .wav files are removed. See assets/audio/CREDITS.md for sources and licences.
Needs ffmpeg on PATH.
"""
import os, re, subprocess, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
K_IMP = "kenney_impact-sounds/Audio/"
K_RPG = "kenney_rpg-audio/Audio/"
K_UI = "kenney_interface-sounds/Audio/"
K_CAS = "kenney_casino-audio/Audio/"
RPG = "oga/rpg_sound_pack/RPG Sound Pack/"
CC = "oga/100-CC0-SFX_0/"
CR = "oga/creatures/"

# name: (max seconds, peak dB, [sources]). A source is a path, or (path, options) where
# options can hold "start" (seconds to skip), "pitch" (playback rate) and "len".
SFX = {
	"gunshot": (0.9, -1, ["oga/22_Pistol.wav", "oga/22_Magnum.wav", CC + "shot_01.ogg", CC + "shot_02.ogg"]),
	"rifle": (1.3, -1, ["oga/sounds/sounds/mosin.wav", "oga/sounds/sounds/sks.wav", "oga/Unkown.wav"]),
	"shotgun": (1.0, -1, ["oga/sounds/sounds/shotty.wav", "oga/Black_Powder.wav"]),
	"explosion": (1.8, -1, [CC + "explosion.ogg", "oga/NenadSimic_-_Muffled_Distant_Explosion.wav"]),
	"punch": (0.4, -3, [K_IMP + "impactPunch_medium_00%d.ogg" % i for i in range(5)]),
	"blunt": (0.5, -2, [K_IMP + "impactPunch_heavy_00%d.ogg" % i for i in range(5)]),
	"hit": (0.35, -4, [K_IMP + "impactGeneric_light_00%d.ogg" % i for i in range(5)]),
	"slash": (0.45, -3, [K_RPG + "knifeSlice.ogg", K_RPG + "knifeSlice2.ogg", K_RPG + "chop.ogg"]),
	"whoosh": (0.45, -4, [RPG + "battle/swing.wav", RPG + "battle/swing2.wav", RPG + "battle/swing3.wav"]),
	"clang": (0.8, -3, [K_IMP + "impactMetal_medium_00%d.ogg" % i for i in range(5)]),
	"glass": (0.7, -4, [K_IMP + "impactGlass_medium_00%d.ogg" % i for i in range(5)]),
	"knock": (0.6, -3, [K_IMP + "impactWood_heavy_00%d.ogg" % i for i in range(3)]),
	"breaking": (1.2, -2, [K_IMP + "impactWood_heavy_003.ogg", K_IMP + "impactWood_heavy_004.ogg", K_IMP + "impactPlank_medium_000.ogg"]),
	"hammer": (0.8, -4, [K_IMP + "impactMining_00%d.ogg" % i for i in range(5)]),
	"stomp": (0.9, -1, [(K_IMP + "impactSoft_heavy_00%d.ogg" % i, {"pitch": 0.75}) for i in range(5)]),
	"bell": (1.6, -4, [K_IMP + "impactBell_heavy_000.ogg", K_IMP + "impactBell_heavy_001.ogg", K_IMP + "impactBell_heavy_002.ogg"]),
	"cloth": (0.5, -5, [K_RPG + "cloth%d.ogg" % i for i in range(1, 5)]),
	"coin": (0.7, -4, [K_CAS + "chips-handle-%d.ogg" % i for i in range(1, 4)] + [K_RPG + "handleCoins.ogg"]),
	"card": (0.4, -5, [K_CAS + "card-place-%d.ogg" % i for i in range(1, 5)]),
	"page": (0.5, -6, [K_RPG + "bookFlip%d.ogg" % i for i in range(1, 4)]),
	"paper": (0.5, -6, [CC + "paper_0%d.ogg" % i for i in range(1, 5)]),
	"click": (0.15, -8, [K_UI + "click_00%d.ogg" % i for i in range(1, 4)]),
	"hover": (0.1, -12, [K_UI + "tick_001.ogg", K_UI + "tick_002.ogg"]),
	"lantern": (0.5, -6, [K_RPG + "metalLatch.ogg", K_RPG + "metalClick.ogg"]),
	"eat": (0.9, -5, [CR + "eat_0%d.ogg" % i for i in range(1, 5)]),
	# Animals and monsters.
	"caw": (0.9, -2, ["oga/crow_caw.wav", "oga/crow_0.ogg"]),
	"bite": (0.6, -2, [RPG + "NPC/beetle/bite-small.wav", RPG + "NPC/beetle/bite-small2.wav", RPG + "NPC/beetle/bite-small3.wav"]),
	"growl": (1.2, -2, ["oga/dog2/dog/dog-growl.flac", "oga/dog2/dog/dog-snarl.flac", "oga/dog2/dog/dog-grumble.flac", "oga/wolf_monster_5.mp3"]),
	"roar": (1.6, -1, [("oga/troll-roars_0.ogg", {"start": t, "len": l}) for t, l in ((0.0, 1.17), (1.86, 1.1), (3.6, 1.17), (7.07, 1.6))] + [CR + "roar_02.ogg"]),
	"howl": (2.2, -3, [CR + "howl.ogg"]),
	"dog": (0.8, -3, ["oga/dog/Dog/Dog Bark 1.wav", "oga/dog/Dog/Dog Bark 2.wav", "oga/dog/Dog/Dog Bark 3.wav"]),
	"screech": (0.7, -4, ["oga/bat/ogg/bat_0%d.ogg" % i for i in range(1, 4)]),
	"eerie": (1.6, -4, [RPG + "NPC/shade/shade%d.wav" % i for i in (10, 11, 12, 13)]),
}

FOOTSTEPS = [K_RPG + "footstep0%d.ogg" % i for i in range(10)]


def run(args):
	return subprocess.run(args, capture_output=True, text=True)


def duration(path):
	r = run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path])
	return float(r.stdout.strip() or 0)


def peak(path):
	r = run(["ffmpeg", "-hide_banner", "-i", path, "-af", "volumedetect", "-f", "null", "-"])
	m = re.search(r"max_volume: (-?[\d.]+)", r.stderr)
	return float(m.group(1)) if m else 0.0


def convert(src, dst, max_len, peak_db, opt):
	tmp = dst + ".tmp.wav"
	filters = []
	if opt.get("pitch"):
		filters.append("asetrate=44100*%s,aresample=44100" % opt["pitch"])
	filters.append("silenceremove=start_periods=1:start_threshold=-40dB")
	args = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error"]
	if opt.get("start"):
		args += ["-ss", str(opt["start"])]
	args += ["-i", src, "-ac", "1", "-ar", "44100", "-af", ",".join(filters), tmp]
	if run(args).returncode != 0:
		raise RuntimeError("convert failed: " + src)
	length = min(duration(tmp), opt.get("len", max_len))
	fade = min(0.25, length * 0.3)
	gain = peak_db - peak(tmp)
	af = "atrim=0:%.3f,afade=t=out:st=%.3f:d=%.3f,volume=%.2fdB" % (length, length - fade, fade, gain)
	r = run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", tmp, "-af", af, "-c:a", "libvorbis", "-q:a", "5", dst])
	os.remove(tmp)
	if r.returncode != 0:
		raise RuntimeError(r.stderr)


def footsteps(base):
	"""Three steps in a row, like the old footsteps clip."""
	for n, start in enumerate((0, 3, 6)):
		srcs = [os.path.join(base, FOOTSTEPS[(start + i) % len(FOOTSTEPS)]) for i in range(3)]
		inputs = []
		for s in srcs:
			inputs += ["-i", s]
		fc = ";".join("[%d]aformat=channel_layouts=mono,adelay=%d[s%d]" % (i, i * 330, i) for i in range(3))
		fc += ";[s0][s1][s2]amix=inputs=3:normalize=0,volume=-3dB"
		dst = os.path.join(OUT, "footsteps_%d.ogg" % (n + 1))
		run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error"] + inputs + ["-filter_complex", fc, "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", dst])


def clear(name):
	for f in glob.glob(os.path.join(OUT, name + ".*")) + glob.glob(os.path.join(OUT, name + "_[0-9]*.*")):
		os.remove(f)


def main():
	base = sys.argv[1]
	for name, (max_len, peak_db, sources) in SFX.items():
		clear(name)
		for i, s in enumerate(sources):
			path, opt = (s if isinstance(s, tuple) else (s, {}))
			convert(os.path.join(base, path), os.path.join(OUT, "%s_%d.ogg" % (name, i + 1)), max_len, peak_db, opt)
		print("%-10s %d" % (name, len(sources)))
	clear("footsteps")
	footsteps(base)
	print("footsteps  3")


if __name__ == "__main__":
	main()
