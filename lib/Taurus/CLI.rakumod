use Taurus::Seconds;

use CSV::Parser;
use Terminal::UI 'ui';
use Terminal::ANSI::OO 't';

# If no arguments are passed then run USAGE & exit.
proto MAIN(|) is export {unless so @*ARGS {put $*USAGE; exit}; {*}}

#| parses Call Logs
multi sub MAIN (
    Str $log where *.IO.f, #= input log file to parse
    UInt :$digits = 10, #= number of significant digits
) is export {
    my @logs;
    my Str %contacts{Str};

    my Instant $timed = now;
    my Promise $initial = start {
        my $p = CSV::Parser.new();
        # 0: Name, 1: Phone number, 2: Call Type,
        # 3: Timestamp, 4: Duration, 5: Sim used.

        # Turn the Hash to an Array.
        @logs = @($log.IO.lines.skip.hyper.map({$p.parse($_)})>>.{0..4}
                  # Discard invalid phone numbers.
                  .grep(*.[1].chars >= $digits));

        for @logs {
            # Discard non-significant digits from phone numbers.
            .[1] .= substr(*-10);

            # Removing leading/trailing whitespaces from names.
            .[0] .= trim;

            # Build contact list.
            %contacts{.[1]} = .[0] if .[0].chars > 0;

            # Store Duration in seconds.
            .[4] = (.[4].split(":")[0] * 60) + .[4].split(":")[1];
        }
    };

    ui.setup: :2panes;
    my $p0 = ui.panes[0];
    my $p1 = ui.panes[1];

    $p0.put: t.bold ~ t.bg-cyan ~ t.black ~t.underline~ "Taurus v" ~ $?DISTRIBUTION.meta<version>;
    $p0.put: "";

    with ui.screen.add-frame(:4height, :40width, :center) -> $f {
        with $f.add-pane -> $p {
            $f.draw;
            until $initial.status {
                $p.splash: "Parsing logs" ~ (".  ", ".. ", "...")[$++ % 3];
                sleep 1;
            }
            $p.splash: "Parsed {@logs.elems} entries in {now - $timed}s.";
            $p.put: " " x 18 ~ "Ok";
            $p.select-last;
            ui.focus($f);
        }
        ui.get-key;
        ui.screen.remove-frame($f);
        ui.focus($f);
    }
    ui.refresh;

    $p0.put: "- Show Records", :meta(:all);
    $p0.put: "";
    # First list Contacts, then sorted phone numbers.
    for @logs.race.map(*.[1]).unique.sort({%contacts{$_} // "Z", $_}) {
        $p0.put: "- " ~ $_ ~ " {%contacts{$_} // ''}", :meta(:number($_));
    }

    $p1.clear;
    $p0.select-first;
    $p0.select(2);
    $p0.on: select => -> :%meta {
        if %meta<all> {
            $p1.clear;
            with @logs {
                my Int $fmt = 16;

                my $outgoing = .grep(*.[2] eqv "Outgoing Call").map(*.[4]).sum;
                my $incoming = .grep(*.[2] eqv "Incoming Call").map(*.[4]).sum;

                $p1.put: "%-*s %s".sprintf($fmt, "Outgoing:", seconds-to-str($outgoing));
                $p1.put: "%-*s %s".sprintf($fmt, "Incoming:",  seconds-to-str($incoming));
                $p1.put: "%-*s %s".sprintf($fmt, "Total:",  seconds-to-str($outgoing + $incoming));
                $p1.put: "";
            }
        } elsif %meta<number> -> $num {
            my Int $fmt = 18;

            $p1.clear;
            $p1.put: "Name:   " ~ $_ with %contacts{$num};
            $p1.put: "Number: " ~ $num;
            $p1.put: "";
            with @logs.grep(*.[1] eqv $num).cache {
                my $outgoing = .grep(*.[2] eqv "Outgoing Call").map(*.[4]).sum;
                my $incoming = .grep(*.[2] eqv "Incoming Call").map(*.[4]).sum;

                $p1.put: "%-*s %s".sprintf($fmt, "Outgoing:", seconds-to-str($outgoing));
                $p1.put: "%-*s %s".sprintf($fmt, "Incoming:", seconds-to-str($incoming));
                $p1.put: "%-*s %s".sprintf($fmt, "Total:", seconds-to-str($outgoing + $incoming));
                $p1.put: "";

                $p1.put: "%-*s %d".sprintf($fmt, "Declined:",
                                           .grep({$_.[2] eqv "Incoming Call" and $_.[4] == 0}).elems);
                $p1.put: "%-*s %d".sprintf($fmt, "Declined (they):",
                                           .grep({$_.[2] eqv "Outgoing Call" and $_.[4] == 0}).elems);
                $p1.put: "%-*s %d".sprintf($fmt, "Missed Calls:",
                                           .grep(*.[2] eqv "Missed Call").elems);
            }
        }
    }

    ui.interact;
    ui.shutdown;
}


multi sub MAIN(
    Bool :$version #= print version
) is export { put "Taurus v" ~ $?DISTRIBUTION.meta<version>; }
