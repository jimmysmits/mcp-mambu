class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.36"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.36/mmcp-v0.0.36-macos-arm64.tar.gz"
      sha256 "d67629857e8b74202f3b66b36eb3a743f64ad1400a275699f7ff035f2c832a36"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.36/mmcp-v0.0.36-linux-amd64.tar.gz"
      sha256 "1efdb38621b0c30016452da673cf6112428ee0792d35f943d2363378d063a1bd"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.36/mmcp-v0.0.36-linux-arm64.tar.gz"
      sha256 "c9fc7683a1a355838ab213a2d1a3c54cbc1227c54abd78d7b4b2f533ffe42c82"
    end
  end

  # ONNX embedding model (multilingual-e5-small, ~118 MB, int8 quantized)
  resource "model" do
    url "https://huggingface.co/Xenova/multilingual-e5-small/resolve/main/onnx/model_quantized.onnx"
    sha256 "f80102d3f2a1229f387d3c81909990d8945513e347b0eab049f7de3c6f98c193"
  end

  resource "tokenizer" do
    url "https://huggingface.co/Xenova/multilingual-e5-small/resolve/main/tokenizer.json"
    sha256 "0b44a9d7b51c3c62626640cda0e2c2f70fdacdc25bbbd68038369d14ebdf4c39"
  end

  def install
    bin.install "mmcp"

    # Install embedding model to share/mmcp/models/
    # mmcp setup detects this via SetupCommand.resolveBrewModelDir()
    (share/"mmcp/models").mkpath
    resource("model").stage do
      (share/"mmcp/models").install "model_quantized.onnx" => "model.onnx"
    end
    resource("tokenizer").stage do
      (share/"mmcp/models").install "tokenizer.json"
    end

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

      This copies the model and catalog to your user directory and builds
      the search index. It only needs to be run once.

      Then configure your MCP client and start the server with:
        mmcp
    EOS
  end
end
