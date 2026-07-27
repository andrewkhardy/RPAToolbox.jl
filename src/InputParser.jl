module InputParser

using YAML

export load_rpa_input

function load_rpa_input(filepath::String)
    input = YAML.load_file(filepath)
    
    file_prefix = replace(basename(filepath), r"\.yml$" => "")
    base_name = get(input, "name", file_prefix)
    data_dir = get(input, "data_dir", "/mnt/home/ahardy/ceph/Data/RPA")
    
    default_prefix = joinpath(data_dir, file_prefix * "_")
    
    if !haskey(input, "output")
        input["output"] = default_prefix
    end
    if !haskey(input, "plots")
        input["plots"] = default_prefix
    end
    if !haskey(input, "interactions")
        input["interactions"] = joinpath(data_dir, base_name * "_interactions.jld2")
    end
    
    if !haskey(input, "unitcell")
        input["unitcell"] = Dict{Any,Any}()
    end
    if !haskey(input["unitcell"], "julia")
        input["unitcell"]["julia"] = joinpath(data_dir, file_prefix * "_dos_scan_data.jld2")
    end
    if !haskey(input["unitcell"], "triqs")
        input["unitcell"]["triqs"] = joinpath(data_dir, file_prefix * "_triqs.npz")
    end
    
    if haskey(input, "gap_equation_rpa")
        if !haskey(input["gap_equation_rpa"], "rpa_data")
            input["gap_equation_rpa"]["rpa_data"] = joinpath(data_dir, file_prefix * "_combined_new.jld2")
        end
    end
    
    return input
end

end
