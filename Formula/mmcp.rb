class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.42"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.42/mmcp-v0.0.42-macos-arm64.tar.gz"
      sha256 "6a776c02c047641d0714f520f78b7867035df51207efb9f756a96ccda4cca9d1"
    else
      odie "mmcp is only distributed for Apple Silicon (arm64) macOS. " \
           "Intel Macs are not supported — build from source: https://github.com/mambu-gmbh/mmcp"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.42/mmcp-v0.0.42-linux-amd64.tar.gz"
      sha256 "f1049df59dab89185cb6b9ab37ea630bc1be81b6cd8abf236d5d8acadb3152d6"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.42/mmcp-v0.0.42-linux-arm64.tar.gz"
      sha256 "851eac6463e656f0a8b8ac06d0f3ddbe74b38098cc7abfd42baca2fd7fdcfe1a"
    end
  end

  def install
    bin.install "mmcp"

    # Install Mambu reference catalog and specs to share/mmcp/reference-apis/
    if File.exist?("reference-apis/mambu/catalog.yaml")
      (share/"mmcp/reference-apis/mambu").mkpath
      (share/"mmcp/reference-apis/mambu").install "reference-apis/mambu/catalog.yaml"
      if File.directory?("reference-apis/mambu/json")
        (share/"mmcp/reference-apis/mambu/json").mkpath
        Dir["reference-apis/mambu/json/*.json"].each do |spec|
          (share/"mmcp/reference-apis/mambu/json").install spec
        end
      end
    end
  end

  def caveats
    <<~EOS
      To complete setup, run:
        mmcp setup --catalog #{share}/mmcp/reference-apis/mambu/catalog.yaml

      This copies the catalog to your user directory and builds the search
      index. It only needs to be run once.

      Then configure your MCP client and start the server with:
        mmcp
    EOS
  end
end
