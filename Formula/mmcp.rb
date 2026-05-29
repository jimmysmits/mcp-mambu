class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.41"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.41/mmcp-v0.0.41-macos-arm64.tar.gz"
      sha256 "671e5ea1411e34f8b997148826b3367efec26033aa36b55b6077d323b82f1da9"
    else
      odie "mmcp is only distributed for Apple Silicon (arm64) macOS. " \
           "Intel Macs are not supported — build from source: https://github.com/mambu-gmbh/mmcp"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.41/mmcp-v0.0.41-linux-amd64.tar.gz"
      sha256 "a47c5c11a58327e10131fbe2a2ca0562ba19c81b85edfb5294d77fcc05e68ecd"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.41/mmcp-v0.0.41-linux-arm64.tar.gz"
      sha256 "7365d3161584a9ee6112f1dc77fa4970cc458842af49ccee818ecb4f5f7d4c7c"
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
