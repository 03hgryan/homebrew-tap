class Cync < Formula
  desc "Sync Claude Code conversations across machines"
  homepage "https://cync-topaz.vercel.app/docs"
  version "0.6.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/03hgryan/homebrew-tap/releases/download/v0.6.0/cync-macos-arm64.tar.gz"
      sha256 "2e119e79544ad78cfafc31a92773211d963965c6d187ee444d48e10ddb8c932f"
    end
    # Intel Macs: not shipped via Homebrew (runner scarcity); use: pipx install cync-cli
  end

  on_linux do
    on_intel do
      url "https://github.com/03hgryan/homebrew-tap/releases/download/v0.6.0/cync-linux-x86_64.tar.gz"
      sha256 "0318b178d66092e5974246186dd6231302043b59720a5439df4d5e1e90022faf"
    end
  end

  def install
    bin.install "cync"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cync --version")
  end
end
