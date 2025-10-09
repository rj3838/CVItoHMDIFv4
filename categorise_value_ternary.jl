function categorise_value_ternary(value::Number)
    my_string = (5 <= value <= 20) ? "1" :
                (20 < value <= 40) ? "2" :
                (value > 40)       ? "3" :
                                     "0" # Default/else case
    return my_string
end