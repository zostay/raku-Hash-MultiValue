use v6;

class Hash::MultiValue is Associative {
    has @.all-pairs;
    has %.singles = @!all-pairs.hash;

    multi method add-pairs(@new is copy) {
        for @!all-pairs.kv -> $i, $v {
            next if $v.defined;
            @!all-pairs[$i] = @new.shift;
            last unless @new;
        }

        @!all-pairs.push: @new;
    }

    multi method add-pairs(*@new) {
        self.add-pairs(@new);
    }

    multi method from-pairs(@pairs) returns Hash::MultiValue {
        self.bless(all-pairs => @pairs);
    }

    multi method from-pairs(*@pairs) returns Hash::MultiValue {
        self.bless(all-pairs => @pairs);
    }

    multi method from-mixed-hash(%hash) returns Hash::MultiValue {
        my @pairs = do for %hash.kv -> $k, $v {
            given $v {
                when Positional { .map: $k => * }
                default         { $k => $v }
            }
        }
        self.bless(all-pairs => @pairs);
    }

    multi method from-mixed-hash(*%hash) returns Hash::MultiValue {
        my $x = self.from-mixed-hash(%hash); # CALLWITH Y U NO WORK???
        return $x;
    }

    method AT-KEY($key) { 
        %!singles{$key} 
    }

    method ASSIGN-KEY($key, $value) { 
        @!all-pairs[ @!all-pairs.grep-index({ .defined && .key eqv $key }) ] :delete;
        self.add-pairs(($key => $value).list);
        %!singles{$key} = $value;
        $value;
    }

    # Not supported, since Pair values can't be bound
    # method BIND-KEY($key, $value is rw) { 
    #     @!all-pairs = @!all-pairs.grep(*.key !eqv $key);
    #     @!all-pairs.push: $key => $value;
    #     %!singles{$key} := $value;
    # }

    method DELETE-KEY($key) {
        @!all-pairs[ @!all-pairs.grep-index({ .defined && .key eqv $key }) ] :delete;
        %!singles{$key} :delete;
    }

    method EXISTS-KEY($key) {
        %!singles{$key} :exists;
    }
    
    method postcircumfix:<( )>($key) is rw {
        my $self = self;
        my @all-pairs := @!all-pairs;
        Proxy.new(
            FETCH => method () { 
                @(@all-pairs.grep({ .defined && .key eqv $key })».value)
            },
            STORE => method (*@new) {
                @all-pairs[ @all-pairs.grep-index({ .defined && .key eqv $key }) ] :delete;
                $self.add-pairs: @new.map($key => *);
                $self.singles{$key} = @new[*-1];
                @new
            },
        )
    }

    method kv { %!singles.kv }
    method pairs { %!singles.pairs }
    method antipairs { %!singles.antipairs }
    method keys { %!singles.keys }
    method values { %!singles.values }

    method all-kv { flat @!all-pairs».kv }
    method all-pairs { flat @!all-pairs }
    method all-antipairs { flat @!all-pairs».antipair }
    method all-keys { flat @!all-pairs».key }
    method all-values { flat @!all-pairs».value }

    method push(*@values) {
        my %new-singles;
        my ($previous, Bool $has-previous);
        for @values -> $v {
            if $has-previous {
                self.add-pairs: $previous => $v;
                %new-singles{ $previous } = $v;

                $has-previous--;
            }
            elsif $v ~~ Enum {
                self.add-pairs: $v.key => $v.value;
                %new-singles{ $v.key } = $v.value;
            }
            else {
                $has-previous++;
                $previous = $v;
            }
        }

        if ($has-previous) {
            warn "Training item in Hash::MultiValue.push";
        }

        %!singles = %!singles, %new-singles;
    }

    # For future consideration
    # method classify-list ...
    # method categorize-list ...

    multi method perl { 
        "Hash::MultiValue.from-pairs(" 
            ~ @!all-pairs.grep(*.defined).sort(*.key cmp *.key).map(*.perl).join(", ") 
            ~ ")"
    }

    multi method gist {
        "Hash::MultiValue.from-pairs(" ~ 
            @!all-pairs.grep(*.defined).sort(*.key cmp *.key).map(-> $elem {
                given ++$ {
                    when 101 { '...' }
                    when 102 { last }
                    default { $elem.gist }
                }
            }).join(", ") ~ ")"
    }
}
