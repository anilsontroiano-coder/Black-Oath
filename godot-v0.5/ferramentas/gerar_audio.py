"""Gera música e efeitos originais; requer Python, NumPy e FFmpeg."""
from pathlib import Path
import subprocess
import wave
import numpy as np

DESTINO = Path(__file__).resolve().parents[1] / "audio"
TAXA = 22050
rng = np.random.default_rng(503)

def salvar(nome, sinal):
    pico = max(1.0, float(np.max(np.abs(sinal))))
    pcm = np.clip(sinal / pico * 0.8, -1, 1)
    with wave.open(str(DESTINO / nome), "wb") as arq:
        arq.setparams((1, 2, TAXA, len(pcm), "NONE", "not compressed"))
        arq.writeframes((pcm * 32767).astype("<i2").tobytes())

duracao = 32.0
t = np.arange(int(duracao * TAXA)) / TAXA
musica = np.zeros(len(t))
# D menor, Si bemol, Sol menor, Lá suspenso. Frases lentas e espaços de silêncio.
acordes = [(146.832, 174.614, 220.0), (116.541, 146.832, 174.614),
           (97.999, 116.541, 146.832), (110.0, 146.832, 164.814)]
for i, acorde in enumerate(acordes):
    inicio = i * 8.0
    local = t - inicio
    env = np.where((local >= 0) & (local < 8), np.sin(np.pi * np.clip(local / 8, 0, 1)) ** 1.5, 0)
    for freq in acorde:
        musica += 0.055 * env * (np.sin(2*np.pi*freq*t) + 0.22*np.sin(2*np.pi*freq*2*t))
notas = [(0.5, 293.665), (3, 349.228), (5, 329.628), (9, 261.626),
         (12, 293.665), (17, 233.082), (20, 220), (24.5, 293.665), (28, 220)]
for inicio, freq in notas:
    local = t - inicio
    env = np.where(local >= 0, np.exp(-np.clip(local, 0, 100) / 2.8) * np.clip(local / .025, 0, 1), 0)
    musica += .12 * env * (np.sin(2*np.pi*freq*local) + .25*np.sin(2*np.pi*freq*2.01*local))
vento = np.convolve(rng.normal(0, 1, len(t)), np.ones(110)/110, mode="same")
musica += vento * .045
# Entradas e saídas suaves evitam estalos na repetição.
musica *= np.minimum(1, t / 1.5) * np.minimum(1, (duracao-t) / 2)
salvar("ambiente_temporario.wav", musica)
subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(DESTINO / "ambiente_temporario.wav"),
                "-c:a", "libvorbis", "-q:a", "3", str(DESTINO / "entre_cinzas.ogg")], check=True)
(DESTINO / "ambiente_temporario.wav").unlink()
t = np.arange(int(.3*TAXA)) / TAXA
salvar("toque.wav", .30*np.sin(2*np.pi*610*t)*np.exp(-t*25)+.04*rng.normal(0,1,len(t))*np.exp(-t*70))
t = np.arange(int(.45*TAXA)) / TAXA
salvar("impacto.wav", .35*rng.normal(0,1,len(t))*np.exp(-t*35)+.25*np.sin(2*np.pi*(95*t-20*t*t))*np.exp(-t*16))
t = np.arange(int(1.5*TAXA)) / TAXA
salvar("sino.wav", .22*(np.sin(2*np.pi*293.665*t)+.5*np.sin(2*np.pi*590*t)+.2*np.sin(2*np.pi*881*t))*np.exp(-t*3)*np.clip(t/.01,0,1))
print("Áudio original gerado.")
