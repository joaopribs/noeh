#encoding: utf-8

class ConjuntoPermanente < ConjuntoPessoas
  def nome_pra_auto_sugestao
    if self.cor.present?
      return "#{self.tipo_do_conjunto} #{self.nome} (#{self.cor.nome})"
    else
      return "#{self.tipo_do_conjunto} #{self.nome}"
    end
  end
end
