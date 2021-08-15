unit module Taurus::Seconds;

sub seconds-to-str(UInt $seconds --> Str) is export {
    given $seconds {
        when * < 60 { $seconds ~ "s" }
        when * < 3600 { "%2dm %2ds".sprintf($_ div 60, $_ % 60) }
        when * < 86400 { "%2dh %2dm %2ds".sprintf($_ div 3600, ($_ % 3600) div 60, $_ % 60) }
        default { "%dd %2dh %2dm %2ds"
                  .sprintf($_ div 86400, ($_ % 86400) div 3600, ($_ % 3600) div 60, $_ % 60) }
    }
}
