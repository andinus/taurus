unit module Taurus::Timestamp;

sub timestamp-to-date(Str $stamp --> Date) is export {
    Date.new(
        "%s-%s-%s".sprintf(.substr(6, 4), .substr(3, 2), .substr(0, 2))
    ) with $stamp;
}
