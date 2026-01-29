class Mmcp < Formula
  desc "Mambu MCP Server"
  homepage "https://www.mambu.com"
  version "v0.0.18"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.18/mmcp-v0.0.18-macos-arm64.tar.gz"
      sha256 "33dfd8b4b66004d1873023064ef1733d39686abd9844b802d9052776ca601128"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.18/mmcp-v0.0.18-linux-amd64.tar.gz"
      sha256 "e3736b4f8bed5cbf1d2afdf3df13851b2288d71f697f9a34584cb3cb6601e380"
    elsif Hardware::CPU.arm?
      url "https://github.com/mambu-gmbh/mmcp-brew/releases/download/v0.0.18/mmcp-v0.0.18-linux-arm64.tar.gz"
      sha256 "07edb47d9d1b8b422cd7508b75a4d95e9f0ded31847c8ae37c27c2739bc546fe"
    end
  end

  def install
    bin.install "mmcp"
  end
end
