package;

import utest.ui.common.HeaderDisplayMode;
import utest.ui.Report;
import utest.Runner;
import cases.*;

class TestAll {
    public static function main() {
        var runner = new Runner();
        
        runner.addCase(new TestUntyped());
        runner.addCase(new TestTypedOperation());
        runner.addCase(new TestAutoMappingParsing());
        runner.addCase(new TestAutoBuiltApiSingleLevel());
        runner.addCase(new TestAutoBuiltApiMultipleLevels());
        #if nodejs // currently on server impl for nodejs
            runner.addCase(new TestServerUntyped());
            runner.addCase(new TestAutoBuiltServerApiSingleLevel());
            runner.addCase(new TestAutoBuiltServerApiMultipleLevels());
            runner.addCase(new TestFibonacci());
        #end

        Report.create(runner, SuccessResultsDisplayMode.AlwaysShowSuccessResults, HeaderDisplayMode.NeverShowHeader);
        runner.run();
    }
}