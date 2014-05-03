class RenomearRemocaoEmRelacoesPessoaGrupo < ActiveRecord::Migration
  def change
    rename_column :relacoes_pessoa_grupo, :data_remocao, :deixou_de_participar_em
  end
end
