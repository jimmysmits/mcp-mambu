class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.34"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.34/mmcp-v0.0.34-macos-arm64.tar.gz"
      sha256 "c928b35357b2faeb287701bbdac0e2be140a2e21f2893d7b450024b3fc44e370"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.34/mmcp-v0.0.34-linux-amd64.tar.gz"
      sha256 "8bb99a9fe520fc3a74114740c117ec979b97a04658704942763106c729cbdf23"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.34/mmcp-v0.0.34-linux-arm64.tar.gz"
      sha256 "d7768c899628a4f3295d539d640ecc914baab32bcbaeb1d1ef7518a29c073df7"
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
