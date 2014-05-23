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

ActiveRecord::Schema.define(version: 20140523104904) do

  create_table "grupos", force: true do |t|
    t.string   "nome"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "eh_super_grupo",  default: false
    t.integer  "quem_criou_id"
    t.integer  "quem_editou_id"
    t.integer  "quem_deletou_id"
    t.datetime "quando_deletou"
  end

  create_table "pessoas", force: true do |t|
    t.string   "nome_facebook"
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
    t.integer  "quem_criou_id"
    t.integer  "quem_editou_id"
    t.integer  "quem_deletou_id"
    t.datetime "quando_deletou"
    t.string   "email_facebook"
    t.string   "url_foto_grande"
    t.string   "url_facebook"
    t.string   "url_foto_pequena"
    t.datetime "ultimo_login"
  end

  create_table "relacoes_pessoa_grupo", force: true do |t|
    t.boolean  "eh_coordenador"
    t.integer  "pessoa_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grupo_id"
    t.integer  "quem_criou_id"
    t.integer  "quem_editou_id"
    t.integer  "quem_deletou_id"
    t.datetime "quando_deletou"
    t.date     "deixou_de_participar_em"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

end
