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

var spinnerOpts = {
    lines: 7, // The number of lines to draw
    length: 4, // The length of each line
    width: 3, // The line thickness
    radius: 2, // The radius of the inner circle
    corners: 0, // Corner roundness (0..1)
    rotate: 0, // The rotation offset
    direction: 1, // 1: clockwise, -1: counterclockwise
    // color: '#fff', // #rgb or #rrggbb or array of colors
    speed: 1, // Rounds per second
    trail: 60, // Afterglow percentage
    shadow: false, // Whether to render a shadow
    hwaccel: false, // Whether to use hardware acceleration
    className: 'spinner', // The CSS class to assign to the spinner
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    top: '12px', // Top position relative to parent
    left: '12px' // Left position relative to parent
};

function iniciarSpinners(mostrarSpinner, $elemento) {
    if (mostrarSpinner == null) {
        mostrarSpinner = true;
    }

    if ($elemento == null) {
        $elemento = $(".img_spinner");
    }

    $elemento.each(function () {
        var cor = $(this).data("corspinner");
        if (cor == null) {
            cor = "#fff";
        }

        spinnerOpts.color = cor;

        $(this).spin(spinnerOpts);

        if (mostrarSpinner) {
            $(this).show();
        }
    });
}

$(function () {
	iniciarSpinners(false);
});