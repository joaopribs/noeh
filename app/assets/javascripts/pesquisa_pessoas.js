// This code adds indexOf function to IE < 9
if(!Array.indexOf){
    Array.prototype.indexOf = function(obj) {
        for(var i=0; i<this.length; i++){
            if(this[i]==obj){
                return i;
            }
        }
        return -1;
    };
}

function BuscaDePessoas(url, containerDosResultados, campoDePesquisa, containerDosDetalhes, dadosExtra, funcaoExtra) {

    var self = this;

    if (dadosExtra == null) {
        dadosExtra = {};
    }

    if (funcaoExtra == null) {
        funcaoExtra = function () {};
    }

    this.resultadoSelecionado = -1,
    this.arrayResultados = [],
    this.timer,
    this.url = url,
    this.containerDosResultados = containerDosResultados,
    this.campoDePesquisa = campoDePesquisa,
    this.containerDosDetalhes = containerDosDetalhes,
    this.dadosExtra = dadosExtra,
    this.funcaoExtra = funcaoExtra,

    this.inicializar = function () {
        // 13 = enter
        // 38 = up arrow
        // 40 = down arrow
        // 27 = esc
        var teclasDeNavegacao = [13, 38, 40, 27];

        $(this.campoDePesquisa).keyup(function (evento) {
            var codigo = evento.keyCode? evento.keyCode : evento.charCode;
            if (teclasDeNavegacao.indexOf(codigo) == -1) {
                evento.preventDefault();
                self.buscar(true);
            }
        });

        $(this.campoDePesquisa).keydown(function (evento) {
            var codigo = evento.keyCode? evento.keyCode : evento.charCode;

            if (teclasDeNavegacao.indexOf(codigo) != -1) {
                evento.preventDefault();

                if (codigo == 38) {
                    self.moverPraCima();
                }
                else if (codigo == 40) {
                    self.moverPraBaixo();
                }
                else if (codigo == 13) {
                    evento.preventDefault();
                    if (self.resultadoSelecionado != -1) {
                        $(self.containerDosResultados).hide();
                        $(this).trigger("blur");
                        self.resultadoSelecionado = -1;
                    }
                }
                else if (codigo == 27) {
                    $(self.containerDosResultados).hide();
                    $(self.containerDosDetalhes).hide();
                    self.resultadoSelecionado = -1;
                }

                $(self.containerDosResultados).find("a:eq(" + self.resultadoSelecionado + ")").addClass('selecionado');
                $(self.containerDosResultados).find("a:not(:eq(" + self.resultadoSelecionado + "))").removeClass('selecionado');
            }
        });

        $(this.campoDePesquisa)
            .focusin(function () {
                self.buscar(false);
            })
            .focusout(function () {
                $(self.containerDosResultados).hide();
            });
    },

    this.buscar = function (esperar) {
        clearTimeout(self.timer);
        var query = $(self.campoDePesquisa).val();

        var tempoAEsperar = esperar ? 800 : 0;

        self.timer = setTimeout(function() {self.mandarBuscaAjax(query)}, tempoAEsperar);
    },

    this.mandarBuscaAjax = function (query) {

        if (query.length < 3) {
            $(self.containerDosResultados).hide();
            return;
        }

        var parametros = $.extend({}, this.dadosExtra, {query: query});

        $.post(
            url,
            parametros,
            function (response) {
                var descricao_quantidade = response.descricao_quantidade;

                resultados = [];
                self.resultadoSelecionado = -1;
                self.arrayResultados = response.pessoas;

                if (descricao_quantidade == "nenhuma") {
                    resultados.push('<p class="conteudo_resultados_pesquisa">');
                    resultados.push('Não foi encontrado nenhum pessoa');
                    resultados.push('</p>');
                } else {
                    resultados.push('<ul class="conteudo_resultados_pesquisa">');
                    $(self.arrayResultados).each(function() {
                        resultados.push('<li>');
                        resultados.push('<a href="#">');

                        var img_src = "";
                        if (this.id_facebook != null && this.id_facebook != "") {
                            img_src = 'http://graph.facebook.com/' + this.id_facebook + '/picture?height=30&width=30';
                        }
                        else {
                            img_src = '/assets/semfoto100.png';
                        }
                        resultados.push('<img src="' + img_src + '" class="imagem_fb_busca"/>');

                        if (this.conjuge != null) {
                            var img_src_conjuge = "";
                            if (this.conjuge.id_facebook != null && this.conjuge.id_facebook != "") {
                                img_src_conjuge = 'http://graph.facebook.com/' + this.conjuge.id_facebook + '/picture?height=30&width=30';
                            }
                            else {
                                img_src_conjuge = '/assets/semfoto100.png';
                            }
                            resultados.push('<img src="' + img_src_conjuge + '" class="imagem_fb_busca"/>');
                        }

                        var texto = "";
                        if (this.conjuge == null) {
                            texto = this.nome + " (" + this.nome_usual + ")";
                        }
                        else {
                            texto = this.nome_usual + " / " + this.conjuge.nome_usual;
                        }

                        resultados.push('<span>' + texto + '</span>');
                        resultados.push('</a>');
                        resultados.push('</li>');
                    });
                    if (descricao_quantidade == "extrapolou") {
                        resultados.push('<li class="extrapolou">Existem mais resultados, seja mais específico</li>');
                    }
                    resultados.push('</ul>');
                }
                resultados = resultados.join('');

                $(self.containerDosResultados).html(resultados);
                $(self.containerDosResultados).show();

                self.atualizarAcaoHoverLinks();

                $("html, body").animate({
                    scrollTop: $(self.campoDePesquisa).offset().top
                }, 500);
            },
            "json"
        );
    },

    this.moverPraCima = function () {
        self.resultadoSelecionado = self.resultadoSelecionado - 1;
        if (self.resultadoSelecionado < 0) {
            self.resultadoSelecionado = 0;
        }
        self.atualizarDetalhesFb();
    },

    this.moverPraBaixo = function () {
        self.resultadoSelecionado = self.resultadoSelecionado + 1;
        if (self.resultadoSelecionado >= $(self.arrayResultados).length) {
            self.resultadoSelecionado = $(self.arrayResultados).length - 1;
        }
        self.atualizarDetalhesFb();
    },

    this.atualizarAcaoHoverLinks = function () {
        $(self.containerDosResultados).find("li a").on("mouseover", function (event) {
            $(self.containerDosResultados).find('a').removeClass('selecionado');
            var indice = $(self.containerDosResultados).find("li a").index(this);
            self.resultadoSelecionado = indice;
            self.atualizarDetalhesFb();
        });
    },

    this.atualizarDetalhesFb = function () {
        if (self.resultadoSelecionado != -1) {
            var pessoa = self.arrayResultados[self.resultadoSelecionado];

            var idPessoa = pessoa.id;
            var idFacebook = pessoa.id_facebook;
            var nome = pessoa.nome;
            var nomeUsual = pessoa.nome_usual;
            var conjuge = pessoa.conjuge;

            if (idFacebook != "") {
                $(this.containerDosDetalhes).find(".imagem_detalhe_pesquisa").first().attr("src", "http://graph.facebook.com/" + idFacebook + "/picture?type=square&height=100&width=100");
            }
            else {
                $(this.containerDosDetalhes).find(".imagem_detalhe_pesquisa").first().attr("src", "/assets/semfoto100.png");
            }

            if (conjuge == null) {
                $(this.containerDosDetalhes).find(".nome_detalhe_pesquisa").html(nome);
                $(this.containerDosDetalhes).find(".nome_usual_detalhe_pesquisa").html("(" + nomeUsual + ")");
                $(this.containerDosDetalhes).find(".imagem_detalhe_pesquisa").last().hide();
            }
            else {
                var nomeUsualConjuge = conjuge.nome_usual;
                var idFacebookConjuge = conjuge.id_facebook;

                if (idFacebookConjuge != "") {
                    $(this.containerDosDetalhes).find(".imagem_detalhe_pesquisa").last().attr("src", "http://graph.facebook.com/" + idFacebookConjuge + "/picture?type=square&height=100&width=100");
                }
                else {
                    $(this.containerDosDetalhes).find(".imagem_detalhe_pesquisa").last().attr("src", "/assets/semfoto100.png");
                }

                $(this.containerDosDetalhes).find(".nome_detalhe_pesquisa").html(nomeUsual + " / " + nomeUsualConjuge);
                $(this.containerDosDetalhes).find(".nome_usual_detalhe_pesquisa").html("")
                $(this.containerDosDetalhes).find(".imagem_detalhe_pesquisa").last().show();
            }

            $(this.containerDosDetalhes).css("display", "inline-block");

            this.funcaoExtra(idPessoa);
        }

    },

    this.limpar = function () {
        $(this.campoDePesquisa).val("");
        $(this.containerDosDetalhes).hide();
    }

};