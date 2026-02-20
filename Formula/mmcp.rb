class Mmcp < Formula
  desc "Mambu MCP Server"
  homepage "https://www.mambu.com"
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

  def install
    bin.install "mmcp"
  end
end
