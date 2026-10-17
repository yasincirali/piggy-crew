import CoreHaptics
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var dokunsal: Dokunsal?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let kayit = engineBridge.pluginRegistry.registrar(forPlugin: "Dokunsal") {
      dokunsal = Dokunsal(messenger: kayit.messenger())
    }
  }
}

/// Core Haptics oynatıcısı (`harcliklarim/dokunsal` kanalı).
///
/// Desenler Dart'ta tanımlı (`lib/services/dokunsal.dart`); burası yalnız
/// onları bir kez `CHHapticPattern`'e çevirir ve çalar. Neden eklenti değil:
/// hazır eklentiler her çalışta yeni motor kuruyordu (gecikme, pil); burada
/// tek motor, otomatik kapanma açık, durur ya da sıfırlanırsa bir sonraki
/// çalışta yeniden başlar. Hata sessizdir: titreşim süsdür.
final class Dokunsal {
  private let kanal: FlutterMethodChannel
  private let destekli = CHHapticEngine.capabilitiesForHardware().supportsHaptics
  private var motor: CHHapticEngine?
  private var calisiyor = false
  private var desenler: [String: CHHapticPattern] = [:]
  private var surekli: CHHapticAdvancedPatternPlayer?

  /// Sürekli dokunun olay keskinliği; `surekliAyarla` bunun üstüne ekler.
  private let surekliKeskinlik: Float = 0.3

  init(messenger: FlutterBinaryMessenger) {
    kanal = FlutterMethodChannel(name: "harcliklarim/dokunsal", binaryMessenger: messenger)
    kanal.setMethodCallHandler { [weak self] call, result in
      self?.isle(call)
      result(nil)
    }
  }

  private func isle(_ call: FlutterMethodCall) {
    guard destekli else { return }
    switch call.method {
    case "kaydet":
      if let harita = call.arguments as? [String: Any] { kaydet(harita) }
    case "cal":
      if let ad = call.arguments as? String { cal(ad) }
    case "surekliBasla":
      surekliBasla()
    case "surekliAyarla":
      if let a = call.arguments as? [String: Any] {
        surekliAyarla(siddet: Dokunsal.sayi(a["s"]), keskinlik: Dokunsal.sayi(a["k"]))
      }
    case "surekliDur":
      surekliDur()
    default:
      break
    }
  }

  private static func sayi(_ v: Any?) -> Float {
    (v as? NSNumber)?.floatValue ?? 0
  }

  // MARK: Desenler

  private func kaydet(_ harita: [String: Any]) {
    for (ad, deger) in harita {
      guard let vuruslar = deger as? [[String: Any]], let desen = Dokunsal.desen(vuruslar) else { continue }
      desenler[ad] = desen
    }
  }

  /// Vuruş listesinden desen. Sürekli vuruşta `e` varsa şiddet sürenin
  /// sonunda ona kayar: olay şiddeti ikisinin büyüğü, eğri çarpanı oran.
  private static func desen(_ vuruslar: [[String: Any]]) -> CHHapticPattern? {
    var olaylar: [CHHapticEvent] = []
    var egriler: [CHHapticParameterCurve] = []
    for v in vuruslar {
      let zaman = TimeInterval(sayi(v["z"]))
      let siddet = sayi(v["s"])
      let keskinlik = sayi(v["k"])
      let sure = TimeInterval(sayi(v["d"]))
      if sure > 0 {
        let son = v["e"] == nil ? siddet : sayi(v["e"])
        let tepe = max(siddet, son, 0.001)
        olaylar.append(CHHapticEvent(
          eventType: .hapticContinuous,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: tepe),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: keskinlik),
          ],
          relativeTime: zaman,
          duration: sure))
        egriler.append(CHHapticParameterCurve(
          parameterID: .hapticIntensityControl,
          controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: siddet / tepe),
            CHHapticParameterCurve.ControlPoint(relativeTime: sure, value: son / tepe),
          ],
          relativeTime: zaman))
      } else {
        olaylar.append(CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: siddet),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: keskinlik),
          ],
          relativeTime: zaman))
      }
    }
    return try? CHHapticPattern(events: olaylar, parameterCurves: egriler)
  }

  // MARK: Motor

  private func hazirMotor() -> CHHapticEngine? {
    if let m = motor {
      if !calisiyor {
        do {
          try m.start()
          calisiyor = true
        } catch {
          return nil
        }
      }
      return m
    }
    guard let m = try? CHHapticEngine() else { return nil }
    m.playsHapticsOnly = true
    m.isAutoShutdownEnabled = true
    m.stoppedHandler = { [weak self] _ in
      DispatchQueue.main.async {
        self?.calisiyor = false
        self?.surekli = nil
      }
    }
    m.resetHandler = { [weak self] in
      DispatchQueue.main.async {
        self?.calisiyor = false
        self?.surekli = nil
      }
    }
    motor = m
    do {
      try m.start()
      calisiyor = true
    } catch {
      return nil
    }
    return m
  }

  private func cal(_ ad: String) {
    guard let desen = desenler[ad], let m = hazirMotor() else { return }
    do {
      try m.makePlayer(with: desen).start(atTime: CHHapticTimeImmediate)
    } catch {
      // Otomatik kapanmadan sonra motor durmuş olabilir: bir kez yeniden başlat.
      calisiyor = false
      guard let m2 = hazirMotor() else { return }
      try? m2.makePlayer(with: desen).start(atTime: CHHapticTimeImmediate)
    }
  }

  // MARK: Sürekli doku (sürüklerken "mıknatıs")

  private func surekliBasla() {
    guard surekli == nil, let m = hazirMotor() else { return }
    let olay = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: surekliKeskinlik),
      ],
      relativeTime: 0,
      duration: 30)
    // Sessiz başlar: şiddet çarpanı 0, Dart yaklaştıkça artırır.
    let baslangic = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: 0, relativeTime: 0)
    do {
      let desen = try CHHapticPattern(events: [olay], parameters: [baslangic])
      let o = try m.makeAdvancedPlayer(with: desen)
      o.loopEnabled = true
      try o.start(atTime: CHHapticTimeImmediate)
      surekli = o
    } catch {
      surekli = nil
    }
  }

  private func surekliAyarla(siddet: Float, keskinlik: Float) {
    guard let o = surekli else { return }
    try? o.sendParameters(
      [
        CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: siddet, relativeTime: 0),
        CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: keskinlik - surekliKeskinlik, relativeTime: 0),
      ],
      atTime: CHHapticTimeImmediate)
  }

  private func surekliDur() {
    try? surekli?.stop(atTime: CHHapticTimeImmediate)
    surekli = nil
  }
}
