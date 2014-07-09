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

ActiveRecord::Schema.define(version: 20140708234722) do

  create_table "auto_sugestao", force: true do |t|
    t.integer  "pessoa_id"
    t.integer  "grupo_id"
    t.string   "sugestao"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "coordenador"
    t.integer  "encontro_id"
  end

  create_table "conjuntos_pessoas", force: true do |t|
    t.integer  "encontro_id"
    t.string   "nome"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tipo"
    t.integer  "cor_id"
  end

  create_table "cores", force: true do |t|
    t.string  "hex_cor"
    t.string  "hex_contraste"
    t.boolean "de_equipe"
    t.boolean "de_conjunto_permanente"
    t.string  "nome"
  end

  create_table "encontros", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_id"
    t.boolean  "padrao",                            default: false
    t.string   "denominacao_conjuntos_permanentes", default: "Círculo"
    t.string   "nome"
    t.string   "local"
    t.string   "tema"
    t.date     "data_inicio"
    t.date     "data_termino"
    t.date     "data_liberacao"
    t.date     "data_fechamento"
  end

  create_table "grupos", force: true do |t|
    t.string   "nome"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tem_encontros", default: false
    t.string   "slug"
  end

  create_table "instrumentos", force: true do |t|
    t.string  "nome"
    t.integer "pessoa_id"
  end

  create_table "pessoas", force: true do |t|
    t.string   "nome"
    t.string   "nome_usual"
    t.date     "nascimento"
    t.string   "rua"
    t.string   "numero"
    t.string   "bairro"
    t.string   "cidade"
    t.string   "estado"
    t.string   "cep"
    t.boolean  "eh_homem"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "eh_super_admin"
    t.integer  "conjuge_id"
    t.string   "complemento"
    t.string   "url_foto_grande"
    t.string   "url_facebook"
    t.string   "url_foto_pequena"
    t.datetime "ultimo_login"
    t.string   "nome_facebook"
    t.string   "email_facebook"
    t.boolean  "auto_inserido",    default: false
  end

  create_table "relacoes_pessoa_conjunto", force: true do |t|
    t.integer  "pessoa_id"
    t.integer  "conjunto_pessoas_id"
    t.boolean  "eh_coordenador"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relacoes_pessoa_grupo", force: true do |t|
    t.boolean  "eh_coordenador"
    t.integer  "pessoa_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_id"
    t.date     "deixou_de_participar_em"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id",                  null: false
    t.text     "data",       limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "telefones", force: true do |t|
    t.string   "telefone"
    t.string   "operadora"
    t.integer  "pessoa_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "telefones", ["pessoa_id"], name: "index_telefones_on_pessoa_id", using: :btree

end
