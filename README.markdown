Quick Start
===========

    svn co svn://svn.tartarus.org/sgt/puzzles@9539
    cd puzzles
    perl mkfiles.pl
    git clone git://github.com/thefloweringash/puzzles-iphone.git iphone
    mkdir -p iphone/Documentation
    pushd iphone/Documentation
        halibut --html ../../help-osx.but ../../puzzles.but
    popd
    open iphone/Puzzles.xcodeproj
