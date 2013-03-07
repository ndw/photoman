/* -*- JavaScript -*- */

var curVis = $("#visible").val();

function changeVisibility() {
    var uri = $("#uri").val();
    var value = $("#visible").val()
    if (value != "public" && value != "private") {
        alert("Unsupported value: " + value);
        $("#visible").val(curVis);
    } else {
        $.get("/ajax/changeVisibility",
              { "uri": uri,
                "value": value });
    }
}

function makeEditable() {
    var id = $(this).attr("id");
    var input = "<input id=\"" + id + "\" size=\"80\">";
    $(this).after(input);
    $(this).remove();
    $("#" + id).change(edited);
    $("#" + id).val($(this).text())
    $("#" + id).focus();
}

function edited() {
    var id = $(this).attr("id");
    var title = $(this).val();
    var span = "<span id=\"" + id + "\" class=\"editable\">" + $(this).val() + "</span>";
    $(this).after(span);
    $(this).remove();
    $("#" + id).click(makeEditable);

    $.get("/ajax/" + id,
          { "uri": $("#" + id + "-uri").val(),
            "value": title });
}

function delTag() {
    var tag = $(this).prev().text();
    $.get("/ajax/del-tag",
          { "uri": window.location.pathname+".xml",
            "value": tag },
          function() { tagDeleted(tag); });
}

function tagDeleted(tag) {
    $("#tag-" + tag).remove();
}

$(document).ready(function() {
    if ($("#vresult") != null) {
        $("#vresult").ajaxSuccess(function(e, xhr, settings) {
            $(this).text("ok");
            if (settings.url.indexOf("ajax/changeVisibility") >= 0) {
                $("#vresult").css("display","inline");
                curVis = $("#visible").val();
                $("#vresult").fadeOut(3000);
            }
        });

        $("#vresult").ajaxError(function(e, xhr, settings) {
            $(this).text("change failed");
            if (settings.url.indexOf("ajax/changeVisibility") >= 0) {
                $("#visible").val(curVis);
            }
        });

        $("#visible").change(changeVisibility);
    }

    $(".editable").each(function(index) { $(this).click(makeEditable); });

    $(".deltag").each(function(index) { $(this).click(delTag); });
});
