class Mmcp < Formula
  desc "Mambu MCP Server"
  homepage "https://www.mambu.com"
  version "v0.0.19"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.19/mmcp-v0.0.19-macos-arm64.tar.gz"
      sha256 "6c3130e9e971a3df9a8eb8090829ecf2dd9452ff3a4161068a0f234e1b6b7510"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.19/mmcp-v0.0.19-linux-amd64.tar.gz"
      sha256 "e2c2366046bb5eeed0397dea04e3510508646358716dca1fea094907dc08a061"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.19/mmcp-v0.0.19-linux-arm64.tar.gz"
      sha256 "ba913f0b4e3b67696c43e0a1f193806420f6d0c52e5981bc5d4b9f7b2e6c273f"
    end
  end

  def install
    bin.install "mmcp"
  end
end
