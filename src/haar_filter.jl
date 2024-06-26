# This file is a part of RadiationDetectorDSP.jl, licensed under the MIT License (MIT).

struct HaarAveragingFilter <: AbstractRadSigFilter{LinearFiltering}
    down_sampling_rate::Int
    length::Int
    HaarAveragingFilter(down_sampling_rate::Int) = new(down_sampling_rate, 2)
end

export HaarAveragingFilter

struct HaarAveragingFilterInstance{T} <: AbstractRadSigFilterInstance{LinearFiltering}
    down_sampling_rate::Int
    length::Int
    n_input::Int
end

function RadiationDetectorDSP.fltinstance(flt::HaarAveragingFilter, input::SamplingInfo{T}) where T
    HaarAveragingFilterInstance{T}(flt.down_sampling_rate, flt.length, length(input.axis))
end

RadiationDetectorDSP.flt_output_smpltype(fi::HaarAveragingFilterInstance) = flt_input_smpltype(fi)
RadiationDetectorDSP.flt_input_smpltype(::HaarAveragingFilterInstance{T}) where T = T
RadiationDetectorDSP.flt_output_length(fi::HaarAveragingFilterInstance) = ceil(Int, fi.n_input/fi.down_sampling_rate)
RadiationDetectorDSP.flt_output_time_axis(fi::HaarAveragingFilterInstance, time::AbstractVector{<:RealQuantity}) = time[1:fi.down_sampling_rate:end]

function RadiationDetectorDSP.rdfilt!(output::AbstractVector{T}, fi::HaarAveragingFilterInstance{T}, input::AbstractVector{T}) where T
    invsqrt = inv(sqrt(T(fi.length)))
    @assert flt_output_length(fi) == length(output) "output length not compatible with filter"
    @inbounds @simd for i in eachindex(output)
        from = (i-1)*fi.down_sampling_rate + 1
        to = from + fi.length - 1
        result::T = zero(T)
        for j in from:to
            result += input[min(end, max(1, j))]
        end
        output[i] = result * invsqrt
    end
    output
end