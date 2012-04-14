/* -*- JavaScript -*- */

$(document).ready(function() {
    $("dd.ex-closed").each(function(index) {
        $(this).css("display", "none");
    });

    $("dt.ex-closed").each(function(index) {
        var span = $(this).children()[0];
        $(span).attr("class", "bright");
        $(span).html("→");
        $(span).click(function() { dtclick(span); });
    });
});

function dtclick(span) {
    var dt = $(span).parent();
    var dd = $(dt).next();

    if ($(dt).hasClass("ex-closed")) {
        $(span).attr("class", "bdown");
        $(span).html("↓");
        $(dd).css("display", "block");
    } else {
        $(span).attr("class", "bright");
        $(span).html("→");
        $(dd).css("display", "none");
    }

    $(dt).toggleClass("ex-closed");
    $(dt).toggleClass("ex-open");
}
