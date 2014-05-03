class AdicionarDataRemocaoARelacoesPessoaGrupo < ActiveRecord::Migration
  def change
    add_column :relacoes_pessoa_grupo, :data_remocao, :date
  end
end
