class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.43"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.43/mmcp-v0.0.43-macos-arm64.tar.gz"
      sha256 "4cdabff1de50dbc51545d7010107069a33028e439396a4d0e0001c5ecb8ff9bd"
    else
      odie "mmcp is only distributed for Apple Silicon (arm64) macOS. " \
           "Intel Macs are not supported — build from source: https://github.com/mambu-gmbh/mmcp"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.43/mmcp-v0.0.43-linux-amd64.tar.gz"
      sha256 "4df80ff926d47049bf4b4ed7c390a5a4e1638751853021f565e749cee6bfc5c3"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.43/mmcp-v0.0.43-linux-arm64.tar.gz"
      sha256 "cc497ed69323fbb0f972e148697d2cf90fe7f23f693a307c86efe45f3ea16977"
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
