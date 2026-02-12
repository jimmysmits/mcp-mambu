class Mmcp < Formula
  desc "Mambu MCP Server"
  homepage "https://www.mambu.com"
  version "v0.0.21"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.21/mmcp-v0.0.21-macos-arm64.tar.gz"
      sha256 "64f9410dd22edaa1fa05b25f3e83c2e24682c5dab0acbd83c8129fbc1446ed81"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.21/mmcp-v0.0.21-linux-amd64.tar.gz"
      sha256 "4f7d49a3e07d7a0f0a43fbafc9722f2a36016e3f8275d7ed80844e6441255e6d"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.21/mmcp-v0.0.21-linux-arm64.tar.gz"
      sha256 "bb25d86a326d6f61863e4d667d62e93ebeccb06827524787fef36976e37a5a97"
    end
  end

  def install
    bin.install "mmcp"
  end
end
