Pod::Spec.new do |spec|
  spec.name                     = "VinnyOCR"
  spec.version                  = "1.0.1"
  spec.summary                  = "OCR library written in Swift powered by the Accelerate and Vision frameworks."

  spec.homepage                 = "https://github.com/igorefremov/VinnyOCR"
  spec.license                  = { :type => "MIT", :file => "LICENSE" }
  spec.author                   = { "Igor Efremov" => "igor@cpgroup.us" }

  spec.ios.deployment_target    = "11.0"
  spec.osx.deployment_target    = "10.13"

  spec.swift_versions           = "5.0"
  spec.frameworks               = "Accelerate", "Vision"

  spec.source                   = { :git => "https://github.com/igorefremov/VinnyOCR.git", :tag => "v#{spec.version}" }
  spec.source_files             = "VinnyOCR/VinnyOCR/*.swift", "VinnyOCR/VinnyOCR/Extensions/*.swift", "VinnyOCR/VinnyOCR/FFNN/*.swift"

  spec.description              = <<-DESC
    VinnyOCR is a fast and small OCR library written in Swift. Powered by the Accelerate and Vision frameworks, it uses a neural network to recognize text. VinnyOCR was created and optimized to recognize short, one line long, alphanumeric codes (e.g. DI49CM). Only iOS and macOS are supported at the moment.
                                  DESC
end
