function process_arguments(args)
    options = Dict{String, Any}() # Use Any to allow different data types
    options["verbose"] = false  # Default value for verbose
    options["count"] = 1      # default value for count
    options["name"] = "World"

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "-v" || arg == "--verbose"
            options["verbose"] = true
            i += 1
        elseif arg == "-c" || arg == "--count"
            if i + 1 <= length(args)
                options["count"] = try
                    parse(Int, args[i+1])
                catch
                    println("Error: --count option requires an integer argument.")
                    exit(1)
                end
                i += 2
            else
                println("Error: --count option requires an argument.")
                exit(1)
            end
        elseif arg == "-n" || arg == "--name"
            if i + 1 <= length(args)
                 options["name"] = args[i+1]
                 i += 2
            else
                 println("Error: --name option requires an argument")
                 exit(1)
            end
        else
            println("Error: Unknown argument: $arg")
            println("Usage: julia script.jl [-v | --verbose] [-c <count> | --count <count>] [-n <name> | --name <name>]")
            exit(1)
        end
    end
    return options
end

function main()
    # Define a function that takes a variable number of arguments
    function test_function(args...)
        println("Number of arguments: ", length(args))
        for (i, arg) in enumerate(args)
            println("Argument $i: $arg")
        end
    end

    # Call the function with different numbers of arguments
    test_function(1, 2, 3)
    test_function("Hello", "World")
    test_function(1.5, "Test", true)

    # Call the function with no arguments
    test_function()


main()

end
