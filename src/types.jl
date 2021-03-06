
abstract type ElementoDetalhe end
struct Moeda <: ElementoDetalhe
    codigo::Symbol
    function Moeda(codigo::Symbol)
        global CONST_MOEDAS
        @assert codigo in CONST_MOEDAS "moeda invalida: $codigo"
        new(codigo)
    end
    Moeda(codigo::String) = Moeda(Symbol(codigo))
end
struct Posicao <: ElementoDetalhe
    codigo::Symbol
    function Posicao(codigo::Symbol)
        global CONST_POSICOES
        @assert codigo in CONST_POSICOES "posicao invalida: $codigo. should be :onshore or :offshore"
        new(codigo)
    end
    "1 = :onshore, 2 = :offshore"
    function Posicao(codigo::String)
        if codigo == "1"
            return Posicao(:onshore)
        elseif codigo == "2"
            return Posicao(:offshore)
        else
            error("codigo deve ser \"1\" ou \"2\"")
        end
    end
end
struct Pais <: ElementoDetalhe
    codigo::Symbol
    function Pais(codigo::Symbol)
        global CONST_PAISES
        @assert codigo in CONST_PAISES "pais invalido: $codigo"
        new(codigo)
    end
    Pais(codigo::String) = Pais(Symbol(codigo))
end

struct DetalheConta
    elementos::Vector{ElementoDetalhe}
    valor::Float64
    function DetalheConta(elementos::Vector{ElementoDetalhe}, valor::Float64)
        @assert length(elementos) > 0 "DetalheConta deve conter ao menos um elemento"
        new(elementos, valor)
    end
end

struct Conta
    codigo::String
    valor::Float64
    detalhes::Vector{DetalheConta}
    function Conta(codigo::String, valor::Float64, detalhes::Vector{DetalheConta})
        if length(detalhes) > 0
            sum_detalhes = sum([d.valor for d in detalhes])
            @assert valor ≈ sum_detalhes "Conta XML2011: soma dos detalhes ($sum_detalhes) deve ser igual ao valor ($valor)"
        end
        return new(codigo, valor, detalhes)
    end
    function Conta(codigo::String, valor::Float64)
        return new(codigo, valor, Vector{DetalheConta}())
    end
    Conta(codigo::String, valor::Int64) = Conta(codigo, Float64(valor))
    function Conta(codigo::String, detalhes::Vector{DetalheConta})
        valor = sum([d.valor for d in detalhes])
        return Conta(codigo, valor, detalhes)
    end
end

get_valor(conta::Conta) = conta.valor
function get_valor(conta::Conta, query::Vector{ElementoDetalhe})
    for d in conta.detalhes
        if all([(q in d.elementos) for q in query])
            return d.valor
        end
    end
    error("valor nao encontrado para os criterios $query")
end

const EMAIL_PATTERN = r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$"i

struct Responsavel
    nome::String
    telefone::String
    email::String
    function Responsavel(nome::String, telefone::String, email::String)
        @assert occursin(EMAIL_PATTERN, email) "email invalido"
        return new(nome, telefone, email)
    end
end

abstract type TipoEnvio end
struct Inclusao <: TipoEnvio end
encode(tipo::Inclusao)::String = "I"
struct Substituicao <: TipoEnvio end
encode(tipo::Substituicao)::String = "S"
function decode_tipo_envio(tipo::String)
    if tipo == "I"
        return Inclusao()
    elseif tipo == "S"
        return Substituicao()
    else
        error("tipo envio invalido: $tipo")
    end
end

struct Doc2011
    data::Date
    cnpj::String
    tipo::TipoEnvio
    responsavel::Responsavel
    contas::Vector{Conta}
    function Doc2011(data::Date, cnpj::String, tipo::TipoEnvio, responsavel::Responsavel, contas::Vector{Conta})
        doc = new(data, cnpj, tipo, responsavel, contas)
        validar(doc)
        return doc
    end
end

function get_conta(doc::Doc2011, codigo::String)
    for conta in doc.contas
        if conta.codigo == codigo
            return conta
        end
    end
    error("conta $codigo inexistente")
end

function has_conta(doc::Doc2011, codigo::String)
    for conta in doc.contas
        if conta.codigo == codigo
            return true
        end
    end
    return false
end

get_valor(doc::Doc2011, codigo::String) = get_valor(get_conta(doc, codigo))

function get_valor(doc::Doc2011, codigo::String, default::Float64)
    if has_conta(doc, codigo)
        return get_valor(doc, codigo)
    else
        return default
    end
end
