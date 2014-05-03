json.array!(@grupos) do |grupo|
  json.extract! grupo, :id, :nome
  json.url grupo_url(grupo, format: :json)
end
