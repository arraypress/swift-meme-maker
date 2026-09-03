//
//  MemeMakerTests.swift
//  MemeMaker
//
//  Offline: the catalogue is bundled and the renderer is given a synthetic
//  background, so nothing here touches the network.
//

import CoreGraphics
import CoreText
import Foundation
import XCTest
@testable import MemeMaker

final class CatalogTests: XCTestCase {

    func testTheCatalogueIsBundledAndComplete() {
        // Bundled rather than fetched, which is what makes listing offline.
        XCTAssertEqual(Catalog.all.count, 211)
        XCTAssertTrue(Catalog.all.allSatisfy { !$0.boxes.isEmpty })
        XCTAssertTrue(Catalog.all.allSatisfy { !$0.name.isEmpty })
    }

    func testEveryBoxOverlapsTheImage() {
        // Not "sits inside it": two templates deliberately bleed past an
        // edge — handshake starts at x = -0.0275 and balloon runs off the
        // right — and cropping them to fit would move text the catalogue
        // placed on purpose. What must hold is that no box is entirely
        // outside, which would draw a caption nobody can see.
        for template in Catalog.all {
            for box in template.boxes {
                XCTAssertGreaterThan(box.scaleX, 0, template.id)
                XCTAssertGreaterThan(box.scaleY, 0, template.id)
                XCTAssertGreaterThan(box.anchorX + box.scaleX, 0, "\(template.id) is off the left")
                XCTAssertGreaterThan(box.anchorY + box.scaleY, 0, "\(template.id) is off the top")
                XCTAssertLessThan(box.anchorX, 1, "\(template.id) is off the right")
                XCTAssertLessThan(box.anchorY, 1, "\(template.id) is off the bottom")
            }
        }
    }

    func testAnExactIdSortsFirst() {
        // "db" is Distracted Boyfriend and also a substring of other names;
        // searching for it must not bury the template actually called that.
        XCTAssertEqual(Catalog.find("db").first?.id, "db")
        XCTAssertGreaterThan(Catalog.find("db").count, 1)
    }

    func testKeywordsAreSearched() {
        // Three-Headed Dragon's only handle is its keyword.
        XCTAssertTrue(Catalog.find("ghidorah").contains { $0.id == "3hd" })
    }

    func testAnUnknownIdIsRefused() {
        XCTAssertThrowsError(try Catalog.template("nothing-like-this")) { error in
            guard case MemeError.unknownTemplate = error else { return XCTFail("got \(error)") }
        }
    }

    func testIdsAreCaseInsensitive() throws {
        XCTAssertEqual(try Catalog.template("DB").id, "db")
    }

    func testBackgroundURLsAreWellFormed() {
        XCTAssertEqual(try? Catalog.template("drake").backgroundURL.absoluteString,
                       "https://api.memegen.link/images/drake.png")
    }
}

final class StyleTests: XCTestCase {

    func testUpperShouts() {
        XCTAssertEqual(BoxStyle.upper.apply(to: "one does not simply"), "ONE DOES NOT SIMPLY")
    }

    func testDefaultLeavesItAlone() {
        XCTAssertEqual(BoxStyle.default.apply(to: "As Typed"), "As Typed")
        XCTAssertEqual(BoxStyle.none.apply(to: "As Typed"), "As Typed")
    }

    func testMockAlternates() {
        XCTAssertEqual(BoxStyle.mock.apply(to: "sure"), "sUrE")
    }
}

final class PaletteTests: XCTestCase {

    func testHexIsRead() {
        let rgb = Palette.hex("#b1e0d0")
        XCTAssertEqual(rgb?.0 ?? 0, 0.694, accuracy: 0.01)
        XCTAssertEqual(Palette.hex("#fff")?.1 ?? 0, 1, accuracy: 0.001)
        XCTAssertNil(Palette.hex("#zzz"))
    }

    func testAnUnknownNameFallsBackToWhite() {
        // White is what a meme is set in, so a name this does not know looks
        // ordinary rather than looking broken.
        XCTAssertEqual(Palette.color("chartreuse").components, Palette.color("white").components)
    }

    func testTheOutlineInvertsSoItIsAlwaysVisible() {
        // A black outline around black letters is just a fatter black letter.
        XCTAssertEqual(Palette.outline(for: "white").components?.first, 0)
        XCTAssertEqual(Palette.outline(for: "black").components?.first, 1)
    }
}

final class TextFittingTests: XCTestCase {

    private var impact: CTFont {
        MemeRenderer.font(named: "Impact") ?? CTFontCreateWithName("Helvetica" as CFString, 100, nil)
    }

    func testShortTextGetsOneBigLine() {
        let (lines, size) = TextFitting.fit("YES", in: CGSize(width: 800, height: 120), font: impact)
        XCTAssertEqual(lines, ["YES"])
        XCTAssertGreaterThan(size, 40)
    }

    func testLongTextWrapsRatherThanShrinkingToNothing() {
        let (lines, size) = TextFitting.fit(
            "ONE DOES NOT SIMPLY WALK INTO MORDOR WITHOUT A VERY GOOD REASON",
            in: CGSize(width: 800, height: 200), font: impact)
        XCTAssertGreaterThan(lines.count, 1)
        XCTAssertGreaterThan(size, 8)
    }

    func testTheBlockFitsTheBox() {
        // The check the first version got wrong: it measured lines against a
        // fraction of the point size rather than the font's own ascent, and
        // sheared the tops off every capital.
        let box = CGSize(width: 600, height: 150)
        let (lines, size) = TextFitting.fit("SOME REASONABLY LONG CAPTION HERE", in: box, font: impact)
        let sized = CTFontCreateCopyWithAttributes(impact, size, nil, nil)
        XCTAssertLessThanOrEqual(Double(lines.count) * TextFitting.lineHeight(sized), box.height)
        for line in lines {
            XCTAssertLessThanOrEqual(TextFitting.width(of: line, font: sized), box.width)
        }
    }

    func testEmptyTextProducesNoLines() {
        XCTAssertTrue(TextFitting.fit("   ", in: CGSize(width: 100, height: 100), font: impact).lines.isEmpty)
    }

    func testAWordWiderThanTheBoxGetsItsOwnLine() {
        // Rather than being cut in half; the shrink loop deals with it.
        let lines = TextFitting.wrap(["SUPERCALIFRAGILISTIC", "OK"], into: 40,
                                     font: CTFontCreateCopyWithAttributes(impact, 100, nil, nil))
        XCTAssertEqual(lines, ["SUPERCALIFRAGILISTIC", "OK"])
    }
}

final class RendererTests: XCTestCase {

    private func background(_ width: Int = 400, _ height: Int = 300) -> CGImage {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    func testImpactIsInstalled() {
        // It ships with macOS, and without it a meme is not a meme.
        XCTAssertNotNil(MemeRenderer.font(named: "Impact"))
    }

    func testRenderingKeepsTheImageSize() throws {
        let image = try MemeRenderer.render(background(), lines: ["TOP", "BOTTOM"],
                                            boxes: TextBox.topAndBottom)
        XCTAssertEqual(image.width, 400)
        XCTAssertEqual(image.height, 300)
    }

    func testMoreLinesThanBoxesIsRefused() {
        // Silently dropping the punchline is worse than refusing to draw it.
        XCTAssertThrowsError(try MemeRenderer.render(background(), lines: ["a", "b", "c"],
                                                     boxes: TextBox.topAndBottom)) { error in
            guard case MemeError.tooManyLines = error else { return XCTFail("got \(error)") }
        }
    }

    func testFewerLinesThanBoxesIsFine() throws {
        XCTAssertNoThrow(try MemeRenderer.render(background(), lines: ["only the top"],
                                                 boxes: TextBox.topAndBottom))
    }

    func testSomethingIsActuallyDrawn() throws {
        // A renderer that quietly draws nothing still returns an image.
        let plain = background()
        let written = try MemeRenderer.render(plain, lines: ["HELLO"], boxes: TextBox.topAndBottom)
        XCTAssertNotEqual(pixels(of: plain), pixels(of: written))
    }

    func testAnEmptyLineDrawsNothing() throws {
        let plain = background()
        let written = try MemeRenderer.render(plain, lines: ["", "   "], boxes: TextBox.topAndBottom)
        XCTAssertEqual(pixels(of: plain), pixels(of: written))
    }

    func testWritingAndReadingBack() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("meme-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: file) }
        try MemeRenderer.write(background(), to: file)
        XCTAssertEqual(try MemeRenderer.image(at: file).width, 400)
    }

    func testAnUnreadableFileIsRefused() {
        XCTAssertThrowsError(try MemeRenderer.image(at: URL(fileURLWithPath: "/nowhere/x.png")))
    }

    private func pixels(of image: CGImage) -> Data {
        (image.dataProvider?.data as Data?) ?? Data()
    }
}
