var listaPessoas;

var timer;

function mostrarNotificacao(mensagem) {
    clearTimeout(timer);

    $(".notificacao").html(mensagem);
    $(".notificacao").show();

    timer = setTimeout(function () {
            $(".notificacao").hide(500);
        }, 4000);

    $.post('/clearnotif');
}