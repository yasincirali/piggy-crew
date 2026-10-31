#!/bin/bash
# 3D karakter kareleri: Blender (bpy) ile render → animasyonlu WebP → assets.
# Kullanım: KARE=/bir/klasor bash tool/karakter3d/uret.sh [karakter...]
# donustur.py kısmi çalışır: KARE'de olmayan sahnelerin eski WebP'si ve satırı kalır.
# Kurulum: python3 -m venv bvenv && bvenv/bin/pip install bpy pillow
# (Python 3.13, bpy 5.2). Cycles CPU, 480², 10 örnek ≈ 1,5 sn/kare.
set -e
D=$(cd "$(dirname "$0")" && pwd); REPO=$(cd "$D/../.." && pwd)
KARE=${KARE:-/tmp/karakter3d}; PY=${PY:-bvenv/bin/python}
O="--boyut 480 --ornek 10 --kamera uygulama"
for k in "${@:-tortu zipzip baykus sincap}"; do for k in $k; do
  for e in minik filiz cicek yildiz; do
    $PY "$D/kumbara.py" atlas "$KARE/uyg/$k/atlas/$e" --evre $e --boyut 480 --ornek 10 --karakter $k > /dev/null
  done
  # Kostüm (2026-10-31): gövdeyle aynı pozlar, ayrı katman; evreden bağımsız.
  $PY "$D/kumbara.py" atlas "$KARE/uyg/$k/atlas/kostum" --evre minik --katman kostum --boyut 480 --ornek 10 --karakter $k > /dev/null
  for s in dokunma arti ziplama keyif etrafa_bak dans; do
    $PY "$D/kumbara.py" sahne $s "$KARE/uyg/$k/$s/beden" --evre minik --katman beden $O --karakter $k > /dev/null
    $PY "$D/kumbara.py" sahne $s "$KARE/uyg/$k/$s/kostum" --evre minik --katman kostum $O --karakter $k > /dev/null
    for e in filiz cicek yildiz; do
      $PY "$D/kumbara.py" sahne $s "$KARE/uyg/$k/$s/$e" --evre $e --katman bitki $O --karakter $k > /dev/null
    done
  done
  # Büyüme (evre): gövde ortak; bitki geçişin hedef evresiyle adlanır.
  $PY "$D/kumbara.py" sahne evre "$KARE/uyg/$k/evre/beden" --evre 'minik>filiz' --katman beden $O --karakter $k > /dev/null
  $PY "$D/kumbara.py" sahne evre "$KARE/uyg/$k/evre/kostum" --evre 'minik>filiz' --katman kostum $O --karakter $k > /dev/null
  for p in 'minik>filiz:filiz' 'filiz>cicek:cicek' 'cicek>yildiz:yildiz'; do
    $PY "$D/kumbara.py" sahne evre "$KARE/uyg/$k/evre/${p##*:}" --evre "${p%%:*}" --katman bitki $O --karakter $k > /dev/null
  done
done; done
KARE=$KARE python3 "$D/donustur.py" "$REPO"
