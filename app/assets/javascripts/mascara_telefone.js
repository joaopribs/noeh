jQuery.fn.extend({

	mascaraTelefone: function () {
		$(this).attr("maxlength", 15);
		$(this).attr("placeholder", "(__) _____-____");

		$(this).off('keyup');
		$(this).on('keyup', function () {
			$(this).val($(this).val().replace(/\D/g, ""));             												//Remove tudo o que não é dígito
			$(this).val($(this).val().replace(/(\d)/, "($1")); 																//Abre parêntese antes do primeiro dígito
			$(this).val($(this).val().replace(/(\(\d{2})/, "$1) ")); 													//Fecha parêntese e coloca espaço depois do ddd
    	$(this).val($(this).val().replace(/(\(\d{2}\)\s\d{4})/, "$1-"));									//Coloca hífen depois da primeira parte do número
    	$(this).val($(this).val().replace(/(\(\d{2}\)\s\d{4})-(\d)(\d{4})/, "$1$2-$3"));	//Muda a posição do hifen caso seja número de 9 dígitos (XXXXX-XXXX ao invés de XXXX-XXXXX)
		});

		$(this).off('blur');
		$(this).on('blur', function () {
			if ($(this).val().match(/\(\d{2}\)\s\d{4}-\d{4}/) == null && $(this).val().match(/\(\d{2}\)\s\d{5}-\d{4}/) == null) {
				$(this).val("");
			}
		});
	}

});