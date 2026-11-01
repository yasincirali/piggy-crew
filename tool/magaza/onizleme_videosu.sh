#!/usr/bin/env bash
# Önizleme videosu: kareleri üret → App Store biçiminde MP4.
#   bash tool/magaza/onizleme_videosu.sh /mutlak/klasor [dil]
# Çıktı <klasor>/harcliklarim_onizleme_<dil>.mp4: 886×1920, 30 kare/sn, H.264
# (yüksek profil), sessiz stereo AAC ses izi. Neden sessiz iz: App Store
# Connect ses izi olmayan önizlemeyi kimi zaman işlemiyor; müzik eklemek
# lisans ve Kids kategorisi kararı (yasin'in).
set -euo pipefail
KLASOR="${1:?klasör ver}"; DIL="${2:-tr}"
flutter test tool/magaza/onizleme_videosu_test.dart --update-goldens \
  --dart-define=CIKTI="$KLASOR" --dart-define=DIL="$DIL"
ffmpeg -y -loglevel error -framerate 30 -i "$KLASOR/$DIL/k_%04d.png" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -map 0:v -map 1:a -shortest \
  -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 16 -r 30 \
  -c:a aac -b:a 256k -movflags +faststart \
  "$KLASOR/harcliklarim_onizleme_$DIL.mp4"
echo "$KLASOR/harcliklarim_onizleme_$DIL.mp4"
