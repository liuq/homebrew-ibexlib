class Ibexlib < Formula
  desc "C++ library for constraint processing over real numbers"
  homepage "http://www.ibex-lib.org/"
  url "https://github.com/ibex-team/ibex-lib/archive/ibex-2.8.6.tar.gz"
  sha256 "f88850be0a62836bd756ce5bac24d1817d939779c332fbdc41bf942472b2e025"
  head "https://github.com/ibex-team/ibex-lib.git"

  bottle do
    cellar :any
    sha256 "e0ec3cc51d9933d7cf447dc947980605210408f78bf4d96e9ad3d48503c436f5" => :catalina
    sha256 "a4ba8be28aecc518997be03a59cbb5f4fc772747818a9cabb20b31946ef0430e" => :mojave
    sha256 "c1e025bfeefd93e9445065c35a677ef375d5d1951bc5226eb578a66d212023f3" => :high_sierra
    sha256 "778927fdd20960097fe3bffd27d2d905d13ffe3f0dfd30af1b3a7cca0f24dbf9" => :sierra
  end

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkg-config" => [:build, :test]
  depends_on :java

  def install
    ENV.cxx11

    # Reported 9 Oct 2017 https://github.com/ibex-team/ibex-lib/issues/286
    ENV.deparallelize

    system "./waf", "configure", "--prefix=#{prefix}",
                                 "--enable-shared",
                                 "--lp-lib=soplex",
                                 "--with-optim",
                                 "--with-jni",
                                 "--java-package-name=org.chocosolver.solver.constraints.real"
    system "./waf", "install"

    pkgshare.install %w[examples plugins/solver/benchs]
    (pkgshare/"examples/symb01.txt").write <<~EOS
      function f(x)
        return ((2*x,-x);(-x,3*x));
      end
    EOS
  end

  test do
    ENV.cxx11

    cp_r (pkgshare/"examples").children, testpath

    # so that pkg-config can remain a build-time only dependency
    inreplace %w[makefile slam/makefile] do |s|
      s.gsub!(/CXXFLAGS.*pkg-config --cflags ibex./,
              "CXXFLAGS := -I#{include} -I#{include}/ibex "\
                          "-I#{include}/ibex/3rd")
      s.gsub!(/LIBS.*pkg-config --libs  ibex./, "LIBS := -L#{lib} -libex")
    end

    (1..8).each do |n|
      system "make", "lab#{n}"
      system "./lab#{n}"
    end

    (1..3).each do |n|
      system "make", "-C", "slam", "slam#{n}"
      system "./slam/slam#{n}"
    end
  end
end
