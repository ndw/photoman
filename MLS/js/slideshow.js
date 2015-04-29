jQuery(document).ready(function ($) {
    var options = {
        $FillMode: 1,
        $AutoPlay: false,
        $ArrowNavigatorOptions: {
            $Class: $JssorArrowNavigator$,
            $ChanceToShow: 2
        }
    };

    var jssor_slider1 = new $JssorSlider$("slider1_container", options);

    function ScaleSlider() {
        var windowWidth = $(window).width();

        if (windowWidth) {
            var windowHeight = $(window).height();
            var originalWidth = jssor_slider1.$OriginalWidth();
            var originalHeight = jssor_slider1.$OriginalHeight();

            if (originalWidth / windowWidth > originalHeight / windowHeight) {
                jssor_slider1.$ScaleHeight(windowHeight);
            } else {
                jssor_slider1.$ScaleWidth(windowWidth);
            }
        } else {
            window.setTimeout(ScaleSlider, 30);
        }
    }

    ScaleSlider();

    $(window).bind("load", ScaleSlider);
    $(window).bind("resize", ScaleSlider);
    $(window).bind("orientationchange", ScaleSlider);
});

