import UIKit
import CoreImage

// MARK: - Design type

enum NailDesign: Equatable {
    case solid(UIColor)
    case gradient(NailGradient)
    case sample(NailSampleDesign)
    case photo(UIImage)

    func ciImage(size: CGSize) -> CIImage? {
        switch self {
        case .solid(let color):
            return CIImage(color: CIColor(color: color))
                .cropped(to: CGRect(origin: .zero, size: size))

        case .gradient(let g):
            return g.ciImage(size: size)

        case .sample(let sample):
            guard let img = sample.image, let cg = img.cgImage else { return nil }
            let src = CIImage(cgImage: cg)
            let sx = size.width  / src.extent.width
            let sy = size.height / src.extent.height
            let scale = max(sx, sy)
            return src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                      .cropped(to: CGRect(origin: .zero, size: size))

        case .photo(let img):
            guard let cg = img.cgImage else { return nil }
            let src = CIImage(cgImage: cg)
            let sx = size.width  / src.extent.width
            let sy = size.height / src.extent.height
            let scale = max(sx, sy)  // cover
            return src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                      .cropped(to: CGRect(origin: .zero, size: size))
        }
    }

    static func == (lhs: NailDesign, rhs: NailDesign) -> Bool {
        switch (lhs, rhs) {
        case (.solid(let a), .solid(let b)):
            return a.rgbaKey == b.rgbaKey
        case (.gradient(let a), .gradient(let b)):
            return a.id == b.id
        case (.sample(let a), .sample(let b)):
            return a.id == b.id
        case (.photo(let a), .photo(let b)):
            return a === b
        default:
            return false
        }
    }
}

private extension UIColor {
    var rgbaKey: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return "\(r)-\(g)-\(b)-\(a)"
    }
}

// MARK: - Sample Designs

struct NailSampleDesign: Identifiable, Hashable {
    let id: Int
    let name: String
    let assetName: String

    var image: UIImage? {
        UIImage(named: assetName)
    }
}

// MARK: - Gradient

struct NailGradient: Identifiable {
    let id = UUID()
    let name: String
    let from: UIColor
    let to: UIColor

    func ciImage(size: CGSize) -> CIImage? {
        guard let filter = CIFilter(name: "CILinearGradient") else { return nil }
        filter.setValue(CIVector(x: size.width * 0.5, y: 0),          forKey: "inputPoint0")
        filter.setValue(CIVector(x: size.width * 0.5, y: size.height), forKey: "inputPoint1")
        filter.setValue(CIColor(color: from), forKey: "inputColor0")
        filter.setValue(CIColor(color: to),   forKey: "inputColor1")
        return filter.outputImage?.cropped(to: CGRect(origin: .zero, size: size))
    }
}

// MARK: - Presets

struct NailPresets {

    // Solid colors
    static let colors: [(name: String, color: UIColor)] = [
        ("ヌード",       UIColor(red: 0.94, green: 0.80, blue: 0.72, alpha: 1)),
        ("ベビーピンク",  UIColor(red: 1.00, green: 0.82, blue: 0.87, alpha: 1)),
        ("ローズ",       UIColor(red: 0.93, green: 0.44, blue: 0.60, alpha: 1)),
        ("コーラル",     UIColor(red: 1.00, green: 0.52, blue: 0.44, alpha: 1)),
        ("レッド",       UIColor(red: 0.86, green: 0.10, blue: 0.16, alpha: 1)),
        ("バーガンディ", UIColor(red: 0.54, green: 0.06, blue: 0.16, alpha: 1)),
        ("ラベンダー",   UIColor(red: 0.80, green: 0.72, blue: 0.96, alpha: 1)),
        ("ライラック",   UIColor(red: 0.88, green: 0.78, blue: 0.94, alpha: 1)),
        ("パープル",     UIColor(red: 0.56, green: 0.20, blue: 0.80, alpha: 1)),
        ("ミント",       UIColor(red: 0.60, green: 0.92, blue: 0.80, alpha: 1)),
        ("スカイブルー", UIColor(red: 0.54, green: 0.82, blue: 0.96, alpha: 1)),
        ("ネイビー",     UIColor(red: 0.10, green: 0.12, blue: 0.44, alpha: 1)),
        ("イエロー",     UIColor(red: 0.98, green: 0.90, blue: 0.22, alpha: 1)),
        ("オレンジ",     UIColor(red: 0.96, green: 0.56, blue: 0.12, alpha: 1)),
        ("グリーン",     UIColor(red: 0.20, green: 0.72, blue: 0.36, alpha: 1)),
        ("ブラウン",     UIColor(red: 0.56, green: 0.32, blue: 0.20, alpha: 1)),
        ("ゴールド",     UIColor(red: 0.88, green: 0.72, blue: 0.22, alpha: 1)),
        ("シルバー",     UIColor(red: 0.78, green: 0.78, blue: 0.82, alpha: 1)),
        ("ローズゴールド", UIColor(red: 0.90, green: 0.68, blue: 0.62, alpha: 1)),
        ("ブラック",     UIColor(red: 0.10, green: 0.08, blue: 0.10, alpha: 1)),
        ("ホワイト",     UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)),
        ("グレー",       UIColor(red: 0.62, green: 0.62, blue: 0.64, alpha: 1)),
    ]

    // Gradients
    static let gradients: [NailGradient] = [
        NailGradient(name: "ピンク→パープル",
                     from: UIColor(red: 1.00, green: 0.72, blue: 0.82, alpha: 1),
                     to:   UIColor(red: 0.72, green: 0.42, blue: 0.90, alpha: 1)),
        NailGradient(name: "ゴールド→ローズ",
                     from: UIColor(red: 0.90, green: 0.72, blue: 0.22, alpha: 1),
                     to:   UIColor(red: 0.90, green: 0.52, blue: 0.62, alpha: 1)),
        NailGradient(name: "ミント→スカイ",
                     from: UIColor(red: 0.52, green: 0.92, blue: 0.80, alpha: 1),
                     to:   UIColor(red: 0.42, green: 0.72, blue: 0.96, alpha: 1)),
        NailGradient(name: "サンセット",
                     from: UIColor(red: 0.98, green: 0.56, blue: 0.32, alpha: 1),
                     to:   UIColor(red: 0.86, green: 0.10, blue: 0.40, alpha: 1)),
        NailGradient(name: "フレンチ",
                     from: UIColor(red: 0.96, green: 0.92, blue: 0.90, alpha: 1),
                     to:   UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)),
        NailGradient(name: "オーロラ",
                     from: UIColor(red: 0.60, green: 0.88, blue: 0.92, alpha: 1),
                     to:   UIColor(red: 0.86, green: 0.60, blue: 0.96, alpha: 1)),
    ]

    static let samples: [NailSampleDesign] = {
        let names = [
            "ジェリーピンク", "ヌードシロップ", "レッドグラス", "バーガンディクロム", "ブラックゴールド",
            "パールホワイト", "オーロラホロ", "ローズマーブル", "ピンクグリッター", "シャンパンヌード",
            "ホワイトオパール", "ハートミルク", "ベージュマーブル", "砂糖グリッター", "アイスホロ",
            "ローズクロム", "コーラルグロス", "白レース", "ブルーオーロラ", "ミントゴールド",
            "コーラルゼリー", "ゴールドクラッシュ", "ラベンダーフォイル", "モカシロップ", "ミントマーブル",
            "デイジーピンク", "ローズゴールド", "レオパード", "ゴールドライン", "ネイビー星空",
            "モーブクロム", "オパールヴェール", "オレンジゼリー", "小花ゴールド", "クリームパール",
            "スカイグロス", "シルバーグリット", "レッドラメ", "ピンクシロップ", "ラベンダーホロ",
            "黒大理石", "ピンクヌード", "ワインラメ", "スターシアー", "ピンクオーロラ",
            "カフェマーブル", "セージクロム", "ゴールドレース", "黒ドット", "シャンパンメタル",
            "オーロラチップ", "空色ゴールド", "キャンディピンク", "レッドゼリー", "ホワイトシェル",
            "ライラッククロム", "ブロンズグリッター", "黒ハート", "ブラックギャラクシー", "ベージュマーブル",
            "シルバーウェーブ", "ピーチホロ", "アイスブルーホロ", "ヌードライン", "ゴールドリング",
            "ブラックラメ", "ネイビーグロス", "ピンク金箔", "ゼブラ", "ピンクオーロラ",
            "ラベンダースモーク", "ルビースパーク", "白パール粒", "グリーンマーブル", "ピーチビジュー",
            "水色スター", "ヌードグロス", "ロゼグリッター", "コーラルマーブル", "エメラルドクロム",
            "シャンパンラメ", "星ピンク", "グレーマーブル", "シルバーホロ", "ピンクスワール",
            "ブラックグロス", "ホログリッター", "ライラックグロス", "ゴールドウェーブ", "ミルキーオパール",
            "ルビークロム", "ミントシロップ", "シルバークラッシュ", "ピンクマーブル", "ティールグリッター",
            "ヌードゴールド", "ラベンダーホロ", "べっ甲", "ローズラメ", "水色ライン",
            "うさぎハート", "銀河ホロ", "くまビジュー", "リボンジュエル", "月星ブルー",
            "ねこピンク", "王冠パープル", "ハートストーン", "雲スター", "黒リボン",
            "星チャーム", "チェリージュエル", "白くまリボン", "ピンク紙吹雪", "魔法スター",
            "パールビジュー", "いちごレッド", "シルバー宝石", "おばけパール", "天使ハート",
            "月チャーム", "うさぎミルク", "アイスホロ", "黒ハート宝石", "雲ブルー",
            "リボンハート", "月星ラメ", "天使ウィング", "カップケーキ", "金ラメミックス",
            "星ミント", "ねこリボン", "姫クラウン", "月オーロラ", "パールハート",
            "わんこミント", "蝶オパール", "黒星ジュエル", "雲しずく", "オーロラ紙吹雪",
            "ハートオパール", "貝殻パール", "ローズハート", "ゴールドリボン", "音符ラベンダー",
            "くまピンク", "氷ホログラム", "ハートリング", "姫ハート", "星空プラネット",
            "リボンパール", "黒ねこ", "ピンクホロ", "シェルアイス", "白うさぎ",
            "シルバーフレーク", "ハート王冠", "桜パール", "紫ホロ", "白くまピンク",
            "赤ハートキー", "透明リボン", "ねこブルー", "星ピンク", "黒ムーン",
            "パールハート雫", "うさぎラベンダー", "白王冠", "オパールミント", "ねこミント",
            "天使ジュエル", "くまキャンディ", "紫ハート", "ミントホロ", "月スター",
            "ピンクリボン", "銀パール", "黒蝶", "ロリポップ", "ハート紙吹雪",
            "星パープル", "泡ハート", "雲スマイル", "ハートシャワー", "くまクラウン",
            "青プラネット", "月ビジュー", "ピンクリボン宝石", "水色ハート", "黒パンダ風",
            "オーロラミックス", "黒ハートシルバー", "天使ハート翼", "うさぎジュエル", "星ゴールド",
            "くまハート", "氷オパール", "赤リボン", "青ラメキャラ", "ねこパール",
            "星座ネイビー", "黒夜オリオン", "青銀星座", "ピンク星雲", "惑星チャーム",
            "流星ラベンダー", "深夜スター", "三日月ゴールド", "赤銀河", "星屑ミックス",
            "星座ブルー", "銀河シルバー", "ティール星雲", "流れ星ブラック", "紫星座",
            "ミルキーウェイ", "紫ピンク星雲", "隕石ラメ", "星座ブラック", "青月リング",
            "銀月ネイビー", "ゴールド星座", "ピンク宇宙塵", "流星群", "四角星座",
            "オパール宇宙", "星尾ゴールド", "紫星図", "月星チャーム", "紫銀河",
            "水色惑星", "パープル星座", "冬の星座", "銀河パープル", "氷宇宙",
            "天文ゴールド", "金星雲", "オーロラ星雲", "星図リング", "流星ホロ",
            "黒金星座", "細星座ライン", "月相ネイビー", "コーラル星", "月軌道",
            "彗星彩り", "土星パープル", "オパール流星", "金星座ライン", "銀星図",
            "白星ホロ", "月惑星", "三日月連なり", "北極星ブルー", "金砂銀河",
            "グリーン星雲", "天球儀ブラック", "星雲ブルー", "紫星座ラメ", "星座ゴールド",
            "四角座ブラック", "ローズ星雲", "円座ゴールド", "星羅針盤", "惑星ブルー",
            "マゼンタ銀河", "銀流星", "紫星チャーム", "青星座", "金流星座",
            "一等星ブラック", "虹銀河", "黒水晶星", "青銀星空", "星座ムーン",
            "ローズ宇宙", "黒星群", "銀河バイオレット", "惑星クリスタル", "天の川ブルー",
            "紫天の川", "天文盤ゴールド", "銀星座", "青星屑", "星月ブラック",
            "金星座群", "双子惑星", "コーラル星屑", "紫流星", "土星ブルー",
            "銀月ブラック", "虹惑星", "紫天球", "ピンク星雲ラメ", "小星座",
            "雪星ブルー", "金銀星屑", "三角星座", "青流星", "白銀ムーン"
        ]

        let generatedPacks = [
            "ジュエルクロム",
            "季節かわいい",
            "Y2Kネオン",
            "上品ミニマル",
            "ゴシックロマン",
            "スイーツ",
            "アート柄"
        ]
        let generatedNames = generatedPacks.flatMap { pack in
            (1...100).map { number in "\(pack)\(number)" }
        }
        let allNames = names + generatedNames

        return (1...1000).map { index in
            NailSampleDesign(
                id: index,
                name: allNames[index - 1],
                assetName: String(format: "nail_sample_%03d", index)
            )
        }
    }()
}
