class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.27"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.27/mmcp-v0.0.27-macos-arm64.tar.gz"
      sha256 "9e7211ecda532bc8e21d5c08aea3e62690d1cfd69e36717145fdbbabff830589"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.27/mmcp-v0.0.27-linux-amd64.tar.gz"
      sha256 "1a97291d78d5da45635df24f7142c75cdd7b6eaf91ef2e6bc8b4fc2b4881d6f9"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.27/mmcp-v0.0.27-linux-arm64.tar.gz"
      sha256 "4a3fa4c3ebf6978058629c1f1610efb33e2d383cce6462c446387903407d079b"
    end
  end

  # ONNX embedding model (nomic-embed-text-v1.5, ~550 MB)
  resource "model" do
    url "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5/resolve/main/onnx/model.onnx"
    sha256 "PLACEHOLDER_MODEL_SHA256"
  end

  resource "tokenizer" do
    url "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5/resolve/main/tokenizer.json"
    sha256 "PLACEHOLDER_TOKENIZER_SHA256"
  end

  def install
    bin.install "mmcp"

    # Install embedding model to share/mmcp/models/
    # mmcp setup detects this via SetupCommand.resolveBrewModelDir()
    (share/"mmcp/models").mkpath
    resource("model").stage do
      (share/"mmcp/models").install "model.onnx"
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
      The ONNX embedding model has been installed to:
        #{share}/mmcp/models/

      The Mambu reference API catalog has been installed to:
        #{share}/mmcp/reference-apis/mambu/catalog.yaml

      To set up MMCP with the Mambu banking APIs:
        export MAMBU_API_KEY="your-api-key"
        export MAMBU_BASE_URL="https://your-tenant.mambu.com/api"
        mmcp setup --catalog #{share}/mmcp/reference-apis/mambu/catalog.yaml

      Or with your own API catalog:
        mmcp setup --catalog /path/to/your/catalog.yaml

      Then start the server with:
        mmcp
    EOS
  end
end
