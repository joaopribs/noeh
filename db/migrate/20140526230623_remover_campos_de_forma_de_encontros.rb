class RemoverCamposDeFormaDeEncontros < ActiveRecord::Migration
  def change
    remove_column :forma_de_encontros, :numeroSolteirosCoordEquipe
    remove_column :forma_de_encontros, :numeroCasaisCoordEquipe
    remove_column :forma_de_encontros, :numeroSolteirosCoordPermanente
    remove_column :forma_de_encontros, :numeroCasaisCoordPermanente
    rename_column :forma_de_encontros, :nomeConjuntoPermanente, :nome_conjunto_permanente
  end
end