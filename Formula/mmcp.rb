class Mmcp < Formula
  desc "MCP Server for OpenAPI — search and invoke any REST API from AI agents"
  homepage "https://github.com/mambu-gmbh/mmcp-brew"
  version "v0.0.38"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.38/mmcp-v0.0.38-macos-arm64.tar.gz"
      sha256 "26ff211eac784a4dc5cc50ca3007043024ce9702d0a32a54c5f400f93575b78e"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.38/mmcp-v0.0.38-linux-amd64.tar.gz"
      sha256 "e4d798628eab6054850a54790f4dadb810ceae4a9cf5b468ff5ecd07c0d5f9d5"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.38/mmcp-v0.0.38-linux-arm64.tar.gz"
      sha256 "08651dd1d6792382cb8b89f57b95ba53e50a3d558f2304bc349df948c001601e"
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
