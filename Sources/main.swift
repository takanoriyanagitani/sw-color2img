import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
import class CoreImage.CIColor
import class CoreImage.CIContext
import struct CoreImage.CIFormat
import class CoreImage.CIImage
import class Foundation.ProcessInfo
import struct Foundation.URL
import func FpUtil.Bind
import typealias FpUtil.IO
import func FpUtil.Lift
import func ImageToPng.ImageWriterNew
import struct ImageToPng.PngWriteOption
import typealias ImageToPng.WriteImage

enum ColToImgErr: Error {
  case invalidArgument(String)
}

struct ImageSize {
  public let width: Int32
  public let height: Int32

  public func toSize() -> CGSize {
    CGSize(width: Double(width), height: Double(height))
  }

  public func toRect() -> CGRect { CGRect(origin: .zero, size: self.toSize()) }

  public func image2finite(_ img: CIImage) -> CIImage {
    img.cropped(to: self.toRect())
  }
}

func str2int32(_ s: String) -> Result<Int32, Error> {
  let oi: Int32? = Int32(s)
  guard let i = oi else {
    return .failure(ColToImgErr.invalidArgument("invalid integer: \( s )"))
  }
  return .success(i)
}

let fcol: CIFormat = .RGBA8

typealias ImageToFs = (URL) -> (CIImage) -> IO<Void>

func str2url(_ s: String) -> URL { URL(fileURLWithPath: s) }

func colorStringToColor(_ cstr: String) -> CIColor {
  CIColor(string: cstr)
}

func envValByKey(_ key: String) -> IO<String> {
  return {
    let values: [String: String] = ProcessInfo.processInfo.environment
    let oval: String? = values[key]
    guard let val = oval else {
      return .failure(ColToImgErr.invalidArgument("env var \( key ) missing"))
    }
    return .success(val)
  }
}

func envKeyToInt32(_ key: String) -> IO<Int32> {
  return Bind(
    envValByKey(key),
    Lift(str2int32),
  )
}

func widthFromEnv() -> IO<Int32> { envKeyToInt32("ENV_WIDTH") }
func heightFromEnv() -> IO<Int32> { envKeyToInt32("ENV_HEIGHT") }

func imageSizeFromEnv() -> IO<ImageSize> {
  Bind(
    widthFromEnv(),
    {
      let width: Int32 = $0
      return Bind(
        heightFromEnv(),
        Lift {
          let height: Int32 = $0
          return .success(
            ImageSize(
              width: width,
              height: height,
            ))
        },
      )
    },
  )
}

func colorStringFromEnv() -> IO<String> { envValByKey("ENV_COLOR_STRING") }

func colorFromEnv() -> IO<CIColor> {
  Bind(
    colorStringFromEnv(),
    Lift { .success(colorStringToColor($0)) },
  )
}

func infiniteImageFromEnv() -> IO<CIImage> {
  Bind(
    colorFromEnv(),
    Lift { .success(CIImage(color: $0)) },
  )
}

func finiteImgFromEnv() -> IO<CIImage> {
  Bind(
    imageSizeFromEnv(),
    {
      let isz: ImageSize = $0
      return Bind(
        infiniteImageFromEnv(),
        Lift {
          let img: CIImage = $0
          return .success(isz.image2finite(img))
        },
      )
    },
  )
}

func pngUrl() -> IO<URL> {
  Bind(
    envValByKey("ENV_OUTPUT_PNG_FILENAME"),
    Lift {
      .success(str2url($0))
    },
  )
}

@main
struct ColorToImage {
  static func main() {
    let pwo: PngWriteOption = .deviceRgb(fmt: fcol)
    let ictx: CIContext = CIContext()
    let iwtr: ImageToFs = ImageWriterNew(ictx: ictx, opt: pwo)

    let outUrl: IO<URL> = pngUrl()
    let oimg: IO<CIImage> = finiteImgFromEnv()

    let color2img2png2url: IO<Void> = Bind(
      outUrl,
      {
        let u: URL = $0
        let wimg: (CIImage) -> IO<Void> = iwtr(u)
        return Bind(
          oimg,
          wimg,
        )
      },
    )

    let res: Result<_, _> = color2img2png2url()

    do {
      try res.get()
    } catch {
      print("\( error )")
    }
  }
}
