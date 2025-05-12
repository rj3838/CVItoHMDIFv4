#!/usr/bin/env julia

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

function main(args)
    if length(args) == 0
        println("No arguments provided. Using default values.")
        args = ["-n", "World"]
    end
    
    options = process_arguments(args)

    if options["verbose"]
        println("Running in verbose mode.")
        println("Count: $(options["count"])")
        println("Name: $(options["name"])")
    end

    for _ in 1:options["count"]
        println("Hello, $(options["name"])!")
    end
end

main(ARGS)