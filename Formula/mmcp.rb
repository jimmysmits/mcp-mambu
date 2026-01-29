class Mmcp < Formula
  desc "Mambu MCP Server"
  homepage "https://www.mambu.com"
  version "v0.0.20"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.20/mmcp-v0.0.20-macos-arm64.tar.gz"
      sha256 "fc78480d4babf55aef2150097aec3f230cad87417ce6ceeec63416c1b30d359b"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.20/mmcp-v0.0.20-linux-amd64.tar.gz"
      sha256 "e3bd5ed19320f0837dee6dfdbfc9ba3c390b8bb1dcba00ebd259ca231b365daf"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.20/mmcp-v0.0.20-linux-arm64.tar.gz"
      sha256 "49272d5724dd2cc0a8f5a0545887eac688520e7bb37c2c359715c367334a8fd1"
    end
  end

  def install
    bin.install "mmcp"
  end
end
