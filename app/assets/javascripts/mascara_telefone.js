function fazerMascaraTelefone($elemento) {
	$elemento.val($elemento.val().replace(/\D/g, ""));             												//Remove tudo o que não é dígito
	$elemento.val($elemento.val().replace(/(\d)/, "($1")); 																//Abre parêntese antes do primeiro dígito
	$elemento.val($elemento.val().replace(/(\(\d{2})/, "$1) ")); 													//Fecha parêntese e coloca espaço depois do ddd
	$elemento.val($elemento.val().replace(/(\(\d{2}\)\s\d{4})/, "$1-"));									//Coloca hífen depois da primeira parte do número
	$elemento.val($elemento.val().replace(/(\(\d{2}\)\s\d{4})-(\d)(\d{4})/, "$1$2-$3"));	//Muda a posição do hifen caso seja número de 9 dígitos (XXXXX-XXXX ao invés de XXXX-XXXXX)
}

jQuery.fn.extend({

	mascaraTelefone: function () {
		$(this).attr("maxlength", 15);
		$(this).attr("placeholder", "(__) _____-____");

		$(this).off('keyup');
		$(this).on('keyup', function (evento) {
			if (evento.keyCode != 8 // Nao fazer se for backspace
				&& evento.keyCode != 46 // Nao fazer se for delete
				&& evento.keyCode != 35 // Nao fazer se for end
				&& evento.keyCode != 36 // Nao fazer se for home
				&& evento.keyCode != 37 // Nao fazer se for esquerda
				&& evento.keyCode != 39) // Nao fazer se for direita
			{ 
				fazerMascaraTelefone($(this));
			}
		});

		$(this).off('blur');
		$(this).on('blur', function () {
			fazerMascaraTelefone($(this));
		});
	}

});