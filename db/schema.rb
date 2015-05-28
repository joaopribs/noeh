# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150528133500) do

  create_table "auto_sugestao", force: :cascade do |t|
    t.integer  "pessoa_id",   limit: 4
    t.integer  "grupo_id",    limit: 4
    t.string   "sugestao",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "coordenador", limit: 1
    t.integer  "encontro_id", limit: 4
    t.integer  "conjuge_id",  limit: 4
  end

  create_table "conjuntos_pessoas", force: :cascade do |t|
    t.integer  "encontro_id",               limit: 4
    t.string   "nome",                      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tipo",                      limit: 255
    t.integer  "cor_id",                    limit: 4
    t.string   "relatorio_file_name",       limit: 255
    t.string   "relatorio_content_type",    limit: 255
    t.integer  "relatorio_file_size",       limit: 4
    t.datetime "relatorio_updated_at"
    t.integer  "equipe_padrao_relacionada", limit: 4
  end

  create_table "cores", force: :cascade do |t|
    t.string  "hex_cor",                limit: 255
    t.string  "hex_contraste",          limit: 255
    t.boolean "de_equipe",              limit: 1
    t.boolean "de_conjunto_permanente", limit: 1
    t.string  "nome",                   limit: 255
    t.string  "classe_css",             limit: 255
    t.string  "hex_cor_hover",          limit: 255
  end

  create_table "encontros", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_id",                          limit: 4
    t.boolean  "padrao",                            limit: 1,   default: false
    t.string   "denominacao_conjuntos_permanentes", limit: 255, default: "Círculo"
    t.string   "nome",                              limit: 255
    t.string   "local",                             limit: 255
    t.string   "tema",                              limit: 255
    t.date     "data_inicio"
    t.date     "data_termino"
    t.date     "data_liberacao"
    t.date     "data_fechamento"
  end

  create_table "grupo_pode_ver_equipes_de_outros_grupos", force: :cascade do |t|
    t.integer  "grupo_id",       limit: 4
    t.integer  "outro_grupo_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grupos", force: :cascade do |t|
    t.string   "nome",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tem_encontros", limit: 1,   default: false
    t.string   "slug",          limit: 255
  end

  create_table "instrumentos", force: :cascade do |t|
    t.string  "nome",      limit: 255
    t.integer "pessoa_id", limit: 4
  end

  create_table "logs_persistentes", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "log",        limit: 255
  end

  create_table "pessoas", force: :cascade do |t|
    t.string   "nome",                        limit: 255
    t.string   "nome_usual",                  limit: 255
    t.date     "nascimento"
    t.string   "rua",                         limit: 255
    t.string   "numero",                      limit: 255
    t.string   "bairro",                      limit: 255
    t.string   "cidade",                      limit: 255
    t.string   "estado",                      limit: 255
    t.string   "cep",                         limit: 255
    t.boolean  "eh_homem",                    limit: 1
    t.string   "email",                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "eh_super_admin",              limit: 1
    t.integer  "conjuge_id",                  limit: 4
    t.string   "complemento",                 limit: 255
    t.string   "url_facebook",                limit: 255
    t.datetime "ultimo_login"
    t.boolean  "auto_inserido",               limit: 1,   default: false
    t.string   "foto_grande_file_name",       limit: 255
    t.string   "foto_grande_content_type",    limit: 255
    t.integer  "foto_grande_file_size",       limit: 4
    t.datetime "foto_grande_updated_at"
    t.string   "foto_pequena_file_name",      limit: 255
    t.string   "foto_pequena_content_type",   limit: 255
    t.integer  "foto_pequena_file_size",      limit: 4
    t.datetime "foto_pequena_updated_at"
    t.string   "url_imagem_facebook",         limit: 255
    t.string   "usuario_facebook",            limit: 255
    t.string   "id_app_facebook",             limit: 255
    t.string   "url_imagem_facebook_pequena", limit: 255
    t.string   "onde_fez_alteracao",          limit: 255
    t.integer  "quem_criou",                  limit: 4
    t.integer  "quem_editou",                 limit: 4
  end

  create_table "recomendacoes_do_coordenador_permanente", force: :cascade do |t|
    t.integer  "conjunto_pessoas_id",       limit: 4
    t.integer  "pessoa_id",                 limit: 4
    t.boolean  "recomenda_pra_coordenador", limit: 1
    t.string   "comentario",                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recomendacoes_equipes", force: :cascade do |t|
    t.integer  "conjunto_pessoas_id", limit: 4
    t.integer  "pessoa_id",           limit: 4
    t.integer  "posicao",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relacoes_pessoa_conjunto", force: :cascade do |t|
    t.integer  "pessoa_id",           limit: 4
    t.integer  "conjunto_pessoas_id", limit: 4
    t.boolean  "eh_coordenador",      limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relacoes_pessoa_grupo", force: :cascade do |t|
    t.boolean  "eh_coordenador",          limit: 1
    t.integer  "pessoa_id",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_id",                limit: 4
    t.date     "deixou_de_participar_em"
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,      null: false
    t.text     "data",       limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "telefones", force: :cascade do |t|
    t.string   "telefone",    limit: 255
    t.string   "operadora",   limit: 255
    t.integer  "pessoa_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "eh_whatsapp", limit: 1
  end

  add_index "telefones", ["pessoa_id"], name: "index_telefones_on_pessoa_id", using: :btree

end
