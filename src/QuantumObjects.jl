module QuantumObjects
import Base: *, ∘, kron, adjoint
import LinearAlgebra: Hermitian, tr,ishermitian,norm
export QuantumObject, Ket, Bra, DensityMatrix, inner,norm,Ensemble

abstract type QuantumObject end

struct Ket <: QuantumObject
    coefficients::AbstractArray{ComplexF64,1}
    function Ket(coefficients)
        new(coefficients ./ norm(coefficients))
    end  
end

struct Bra <: QuantumObject
    k::Ket
end

norm(k1::Ket) = 1.0
norm(k1::Bra) = 1.0

Ket(b::Bra) = b.k

Base.adjoint(k::Ket) = Bra(k)
Base.adjoint(b::Bra) = Ket(b)

Base.:*(k1::Ket, k2::Ket) = inner(k1, k2)
Base.:*(b::Bra, k::Ket) = inner(Ket(b), k)

struct DensityMatrix <: QuantumObject
    matrix::Hermitian{ComplexF64, Matrix{ComplexF64}}
    function DensityMatrix(rho::Matrix{ComplexF64}, to_normalize=true:: Bool)
        #if rho != adjoint(rho) 
        if !ishermitian(rho)
            error("Density Matrix has to be Hermitian!")
        end
        if !to_normalize & (real(tr(rho)) > 1.0)
            error("Density Matrix should have Trace smaller than or equal to  1")
        elseif to_normalize 
            rho = rho ./ tr(rho)
        end
            new(Hermitian(rho))
    end
    function DensityMatrix(ρ::Hermitian{ComplexF64, Matrix{ComplexF64}},to_normalize=true::Bool)
        if !to_normalize & (real(tr(ρ)) > 1.0)
            error("Density Matrix should have Trace smaller than or equal to  1")
        elseif to_normalize 
            ρ= ρ ./ tr(ρ)
        end
            new(ρ)
    end 
    function DensityMatrix(ket::Ket)
        new(Hermitian(ket.coefficients'.*ket.coefficients))
    end
end

inner(ρ::DensityMatrix, σ::DensityMatrix) = tr(ρ.matrix * σ.matrix)
inner(k1::Ket, k2::Ket) = k1.coefficients' * k2.coefficients
Base.:*(ρ::DensityMatrix, σ::DensityMatrix) = inner(ρ, σ)

norm(ρ::DensityMatrix) = sqrt(real(inner(ρ,ρ)))::Float64

Base.kron(k1::Ket, k2::Ket) = Ket(k1.coefficients ⊗ k2.coefficients)
Base.kron(b1::Bra, b2::Bra) = Bra(b1.k ⊗ b2.k)
Base.kron(ρ1::DensityMatrix, ρ2::DensityMatrix) = DensityMatrix(ρ1.matrix ⊗ ρ2.matrix)

⊗ = Base.kron

Matrix(ρ::DensityMatrix) =  ρ.matrix
Ensemble(probs::Vector{Float64}, ρs::Vector{DensityMatrix}) = DensityMatrix(sum(probs.*Matrix.(ρs)),false)
Ensemble(probs::Vector{Float64}, kets::Vector{Ket}) = Ensemble(probs,DensityMatrix.(kets))
Ensemble(probs::Vector{Float64}, bras::Vector{Bra}) = Ensemble(probs,Ket.(Bra))




end
