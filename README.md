![Logo](https://github.com/igorefremov/VinnyOCR/raw/master/Trainer/VinnyOCR%20Trainer/Assets.xcassets/AppIcon.appiconset/Icon-128.png)

# VinnyOCR

VinnyOCR is a fast and small OCR library written in Swift. Powered by the Accelerate and Vision frameworks, it uses a neural network to recognize text.
VinnyOCR was created and optimized to recognize short, one line long, alphanumeric codes (e.g. DI49CM). Only iOS and macOS are supported at the moment.

## Inspiration

This project was inspired by [SwiftOCR](https://github.com/garnele007/SwiftOCR). The difference between the two projects is that VinnyOCR uses internal
Apple frameworks (`Accelerate` and `Vision`) for image manipulation and text location.

## Features

- [x] Easy to use training utility

- [x] High accuracy

- [x] Fast

- [x] Small

## Requirements

- iOS 11.0+/macOS 10.13+

- Swift 5.0+

## Installation

### CocoaPods

To integrate VinnyOCR into your Xcode project using CocoaPods, add it to your `Podfile`:

`pod 'VinnyOCR', '~> 1.0.0'`

## How it Works

1. Input image is thresholded (binarized)

2. Characters are located within the image and individually converted into float arrays

3. Each float array is fed through the neural network

## How to Use

Using VinnyOCR is very simple.

```swift
import VinnyOCR

let modelUrl = Bundle.main.url(forResource: "VinnyOCR", withExtension: "ocr")!
let vinny = VinnyOCR(url: modelUrl)!

vinny.recognize(someImage) { (text) in
  print(text)
}
```

VinnyOCR runs much faster when the build configuration is set to `Release`.

## Training

To train a model for use, clone this repository and open the `VinnyOCR Trainer` Xcode project found in the `Trainer` directory.

After starting the training app, do the following:

1. Select which fonts you want the model to train with by clicking the checkbox in the `Should Train?` column for each font.

2. Select which backgrounds you want the model to train with by clicking `Choose Backgrounds` and selecting some image files. Sample training backgrounds are provided
   in the `Trainer/Sample Backgrounds/` directory of this repository.

3. Select where to output the model file by clicking `Choose Output Directory`. Once training is complete, the model file will be saved to this directory.

4. Press `Start Training`. The default error threshold is set to a value that the network will most likely not reach. Instead, after starting training, wait 5-10 minutes
   and press `Stop Training` - the generated model will work as long as the model error is less than 100. The model error can be seen next to the start/stop training
   button in `<current model error>/<target model error>` format.

### Notes

- After you start training, if the model error does not come below 100 after a minute, restart the training process by by pressing `Stop Training` and `Start Training`.
  This will cause a network with new weights to be generated.

- Training parameters can be modified by editing the values in `TrainingParameters.swift`.

## Planned Improvements

- [ ] Add training screenshots to README

- [ ] Distort generated training images during training

## Acknowledgements

- [SwiftOCR](https://github.com/garnele007/SwiftOCR) for inspiring this project.

- [Swift-AI](https://github.com/Swift-AI/Swift-AI) for providing the code that is used by the neural network within this project.

## License

VinnyOCR is released under the MIT license. See [LICENSE](https://github.com/igorefremov/VinnyOCR/blob/master/LICENSE) for details.
