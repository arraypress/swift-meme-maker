# Swift MemeMaker

Memes, rendered on this machine. Impact, white, black outline.

```swift
import MemeMaker

let template = try Catalog.template("drake")            // 211 of them, bundled
let background = try await Backgrounds(directory: cache).image(for: template)
let meme = try MemeRenderer.render(background,
                                   lines: ["writing a bash script", "shipping a swift cli"],
                                   boxes: template.boxes)
try MemeRenderer.write(meme, to: out)

// Any image at all:
try MemeRenderer.render(photo, lines: ["top", "bottom"], boxes: TextBox.topAndBottom)
```

No account, no watermark, no AI, no upload. The one network call is fetching a
template's background the first time you use it; after that it is cached and
everything is offline.

## The catalogue is bundled

211 templates with their **text-box geometry** — where each line goes, in
fractions of the image — generated from memegen's own `config.yml` files
(MIT, © Jace Browning). That is 103 KB inside the library, and it is what
makes Distracted Boyfriend put three captions on three people rather than
splitting the image in half.

Listing and searching are therefore instant and offline. Only the background
images are fetched, once each, because they belong to whoever made the memes.

Two templates deliberately bleed past an edge — `handshake` starts at
x = −0.0275, `balloon` runs off the right — so geometry is validated as
*overlapping* the image, not as fitting inside it. Cropping them would move
text the catalogue placed on purpose.

## Two things that had to be measured

**`CTLineDraw` ignores the context's fill colour.** It takes the colour from
the attributed string and defaults to black — so the first version of this
drew solid black letters with a black outline and looked like a font problem.
Colours go in the string now, with a negative `kCTStrokeWidthAttributeName`
so one pass fills and strokes, and the outline stays proportional however far
the text has been shrunk.

**Line height comes from the font, not from the point size.** Impact's ascent
is 0.89 em; laying lines out at 0.8 put the first line three pixels above its
box and sheared the tops off every capital. `TextFitting` measures with
`CTFontGetAscent` and `CTFontGetDescent`.

## Fitting

Text is set as large as it will go: the search runs down from a size the box
could not hold, wrapping greedily, until both the block height and every
line's width fit. It stops at 8 points rather than shrinking to nothing —
text too small to read is not better than text that slightly overflows. A word
wider than the box gets its own line rather than being cut in half.

## Tested

26 tests, offline: the bundled catalogue's size and geometry, exact-id search
ordering, keyword search, the casing styles including `mock`, hex and named
colours, the outline inverting so it is visible on black text, the fitted
block genuinely fitting its box, and a render that actually changes pixels —
with an empty caption that must not.

## Licence

MIT. The bundled template geometry is from
[memegen](https://github.com/jacebrowning/memegen), also MIT. The background
images are not redistributed here; they are fetched from
`api.memegen.link` and belong to their creators.
