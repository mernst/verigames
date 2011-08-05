NOTE: this code assumes that you have an environment variable named $CHECKERS
storing the location of your checkers folder in your copy of the checker
framework

ant targets:

   build (default) - Builds the source files in src/ to bin/

   check-nullness - Runs the nullness checker on the files in src/

   clean - Deletes the files in bin/

   test - Runs all tests
      
      test.level - Runs all the tests in the level package

      test.levelBuilder - Runs all the tests in the levelBuilder package

   javadoc - Generates Javadoc for public members

   javadoc.proteected - Generates Javadoc for public and protected members

   javadoc.private - Generates Javadoc for public, protected, and private
   members
