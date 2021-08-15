use CSV::Parser;
use Terminal::UI;
use Terminal::Spinners;
use Text::Table::Simple;

#| parses Call Logs
unit sub MAIN (
    Str $log where *.IO.f, #= input log file to parse
    UInt :$digits = 10, #= number of significant digits
);

my @logs;
my Str %contacts{Str};
Spinner.new(:type<bounce2>).await: Promise.start: {
    my $p = CSV::Parser.new();
    # 0: Name, 1: Phone number, 2: Call Type, 3: Timestamp,
    # 4: Duration, 5: Sim used.

    # Turn the Hash to an Array.
    @logs = @($log.IO.lines.skip.hyper.map({$p.parse($_)})>>.{0..4}
              # Discard invalid phone numbers.
              .grep(*.[1].chars >= $digits));

    # Discard non-significant digits from phone numbers.
    .[1] = .[1].substr(*-10) for @logs;

    # Build contact list.
    %contacts{.[1]} = .[0] for @logs.grep(*.[0].chars > 0);
};
