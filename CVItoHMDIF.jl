# code created to allow compilation to a standalone executable using PackageCompiler.jl
module CVItoHMDIF

include("CVItoHMDIF_v2.jl")
using .CVItoHMDIF_v2   # adjust to the actual module name inside that file

function julia_main()::Cint
    try
        CVItoHMDIF_v2.run_conversion(ARGS)
        return 0
    catch e
        @error "Unhandled error" exception=(e, catch_backtrace())
        return 1
    end
end

end # module
