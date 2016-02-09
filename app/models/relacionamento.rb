#encoding: utf-8

class Relacionamento < ActiveRecord::Base

  default_scope {
    joins(:outra_pessoa).order('pessoas.nome ASC')
  }

  belongs_to :pessoa
  belongs_to :outra_pessoa, class_name: 'Pessoa', foreign_key: :outra_pessoa_id
  belongs_to :padrao_relacionamento

  def relacionamento
    if self.padrao_relacionamento.blank?
      return ''
    end

  	if outra_pessoa.eh_homem
  		return self.padrao_relacionamento.relacionamento_masculino
		else
			return self.padrao_relacionamento.relacionamento_feminino
		end
	end

end
