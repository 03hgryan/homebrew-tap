class Cync < Formula
  desc "Sync Claude Code conversations across machines"
  homepage "https://www.cync.run/docs"
  version "0.7.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/cync-cli/homebrew-tap/releases/download/v0.7.0/cync-macos-arm64.tar.gz"
      sha256 "96fd8fc4b84af3eafca772dc3fdaacc0614884a8c7180bb4ba508bbee33bc150"
    end
    # Intel Macs: not shipped via Homebrew (runner scarcity); use: pipx install cync-cli
  end

  on_linux do
    on_intel do
      url "https://github.com/cync-cli/homebrew-tap/releases/download/v0.7.0/cync-linux-x86_64.tar.gz"
      sha256 "ae8fce6763a4b54a5bb334417b4ebde8e3fbd854d31496e09d7e39ee94bcfc7d"
    end
  end

  def install
    bin.install "cync"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cync --version")
  end
end
