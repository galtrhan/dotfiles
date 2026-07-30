function _compress_dir
    set -l dir $PWD
    set -l home_len (string length "$HOME")
    if test (string sub -s 1 -l $home_len "$PWD") = "$HOME"
        if test "$HOME" = "$PWD"
            set dir '~'
        else
            set dir '~'(string sub -s (math $home_len + 1) "$PWD")
        end
    end

    if test "$dir" = /; or test -z "$dir"
        echo $dir
        return
    end

    set -l parts (string split / $dir)
    if test -z "$parts[1]"
        set is_absolute 1
        set parts $parts[2..-1]
    end
    set -l count (count $parts)

    for i in (seq $count)
        set -l s $parts[$i]
        if test (string length "$s") -gt 32
            set parts[$i] "..."(string sub -s -29 "$s")
        end
    end

    if test $count -le 3
        if set -q is_absolute
            echo /(string join / $parts)
        else
            string join / $parts
        end
    else
        set -l result $parts[1] .. .. $parts[(math $count - 1)] $parts[$count]
        if set -q is_absolute
            echo /(string join / $result)
        else
            string join / $result
        end
    end
end
