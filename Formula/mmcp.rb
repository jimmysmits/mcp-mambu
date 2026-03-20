class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.31"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.31/mmcp-v0.0.31-macos-arm64.tar.gz"
      sha256 "981f091f554faa595a70b5c109a745edd9f2a5c4ada42703359b9117dac705af"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.31/mmcp-v0.0.31-linux-amd64.tar.gz"
      sha256 "041de8640d14e9c50622fff4abde6bdb2c1b5f8a35ee743ca52f8ebd3bf155bc"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.31/mmcp-v0.0.31-linux-arm64.tar.gz"
      sha256 "f821a58846e2c1b3879002fbbe42452163cf93d082a88e78ec31c9ccd28206db"
    end
  end

  # ONNX embedding model (nomic-embed-text-v1.5, ~550 MB)
  resource "model" do
    url "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5/resolve/main/onnx/model.onnx"
    sha256 "147d5aa88c2101237358e17796cf3a227cead1ec304ec34b465bb08e9d952965"
  end

  resource "tokenizer" do
    url "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5/resolve/main/tokenizer.json"
    sha256 "d241a60d5e8f04cc1b2b3e9ef7a4921b27bf526d9f6050ab90f9267a1f9e5c66"
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

  def post_install
    catalog = share/"mmcp/reference-apis/mambu/catalog.yaml"
    if catalog.exist?
      ohai "Running mmcp setup (building search index — this may take a few minutes)..."
      system bin/"mmcp", "setup", "--catalog", catalog
    end
  end

  end
end
